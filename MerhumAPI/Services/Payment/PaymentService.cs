using MassTransit;
using MerhumAPI.Common;
using MerhumAPI.Data;
using MerhumAPI.Models;
using MerhumAPI.DTOs.Payment;
using MerhumAPI.Messages;
using Microsoft.EntityFrameworkCore;
using PaymentEntity = MerhumAPI.Models.Payment;

namespace MerhumAPI.Services.Payment;

public class PaymentService :IPaymentService
{
	private const decimal DefaultBamToEurRate = 1.95583m;

	private readonly ApplicationDbContext _db;
	private readonly IPayPalService _payPalService;
	private readonly IPublishEndpoint _publishEndpoint;
	private readonly IConfiguration _configuration;
	private readonly ILogger<PaymentService> _logger;
		private readonly INotificationService _notificationService;

	public PaymentService(
	    ApplicationDbContext db,
	    IPayPalService payPalService,
	    IPublishEndpoint publishEndpoint,
	    IConfiguration configuration,
	    ILogger<PaymentService> logger,
		    INotificationService notificationService)
	{
		_db = db;
		_payPalService = payPalService;
		_publishEndpoint = publishEndpoint;
		_configuration = configuration;
		_logger = logger;
			_notificationService = notificationService;
	}

	public async Task<PaymentResponseDto> InitiatePaymentAsync(int serviceOrderId, string? scopeToUserId)
	{
		var order = await _db.ServiceOrders
		    .Include(o => o.Deceased)
		    .FirstOrDefaultAsync(o => o.Id == serviceOrderId)
		    ?? throw new KeyNotFoundException("Narudžba nije pronađena.");

		// only the family that owns the deceased pays for the order
		if (scopeToUserId != null && order.Deceased.UserId != scopeToUserId)
			throw new UnauthorizedAccessException("Nemate pristup ovoj narudžbi.");

		var live = await _db.Payments
		    .Where(p => p.ServiceOrderId == serviceOrderId)
		    .Where(p => p.Status == PaymentStatus.Completed || p.Status == PaymentStatus.Pending)
		    .Select(p => p.Status)
		    .FirstOrDefaultAsync();

		if (live == PaymentStatus.Completed)
			throw new InvalidOperationException("Ova narudžba je već plaćena.");

		if (live == PaymentStatus.Pending)
			throw new InvalidOperationException("Plaćanje za ovu narudžbu je već pokrenuto.");

		var eurAmount = Math.Round(order.Price / GetBamToEurRate(), 2, MidpointRounding.AwayFromZero);

		var payment = new PaymentEntity
		{
			ServiceOrderId = order.Id,
			Amount = eurAmount,
			Currency = "EUR",
			Status = PaymentStatus.Pending
		};
		_db.Payments.Add(payment);
		await _db.SaveChangesAsync();

		var (paypalOrderId, approvalUrl) = await _payPalService.CreateOrderAsync(eurAmount, "EUR");

		payment.PaypalOrderId = paypalOrderId;
		await _db.SaveChangesAsync();

		return new PaymentResponseDto
		{
			PaymentId = payment.Id,
			PaypalOrderId = paypalOrderId,
			ApprovalUrl = approvalUrl,
			Status = payment.Status.ToString()
		};
	}

	public async Task<bool> CompletePaymentAsync(string paypalOrderId, string? scopeToUserId)
	{
		var payment = await _db.Payments
		    .Include(p => p.ServiceOrder).ThenInclude(o => o.Deceased)
		    .FirstOrDefaultAsync(p => p.PaypalOrderId == paypalOrderId)
		    ?? throw new KeyNotFoundException("Plaćanje nije pronađeno.");

		if (scopeToUserId != null && payment.ServiceOrder.Deceased.UserId != scopeToUserId)
			throw new UnauthorizedAccessException("Nemate pristup ovom plaćanju.");

		if (payment.Status == PaymentStatus.Completed)
			return true;

		var (success, captureId) = await _payPalService.CaptureOrderAsync(paypalOrderId);

		if (!success)
		{
			payment.Status = PaymentStatus.Failed;
			await _db.SaveChangesAsync();
			return false;
		}

		payment.Status = PaymentStatus.Completed;
		payment.PaypalCaptureId = captureId;
		payment.CompletedAt = DateTime.UtcNow;
		await _db.SaveChangesAsync();

		await AdvanceOrderAfterPaymentAsync(payment.ServiceOrderId);
		await PublishConfirmationAsync(payment);
		await NotifyServiceOrderOwnerAsync(payment.ServiceOrderId, "Plaćanje uspješno", "Vaše plaćanje pogrebne usluge je uspješno izvršeno.");
		return true;
	}

	// without this an abandoned PayPal session would keep the order blocked forever
	public async Task<bool> CancelPendingPaymentAsync(int serviceOrderId, string? scopeToUserId)
	{
		var payment = await _db.Payments
		    .Include(p => p.ServiceOrder).ThenInclude(o => o.Deceased)
		    .Where(p => p.ServiceOrderId == serviceOrderId && p.Status == PaymentStatus.Pending)
		    .OrderByDescending(p => p.Id)
		    .FirstOrDefaultAsync();

		if (payment == null) return false;

		if (scopeToUserId != null && payment.ServiceOrder.Deceased.UserId != scopeToUserId)
			throw new UnauthorizedAccessException("Nemate pristup ovom plaćanju.");

		payment.Status = PaymentStatus.Cancelled;
		await _db.SaveChangesAsync();
		return true;
	}

	public async Task<PaymentStatusDto> GetStatusAsync(int serviceOrderId, string? scopeToUserId)
	{
		if (scopeToUserId != null)
		{
			var visible = await _db.ServiceOrders.AnyAsync(o => o.Id == serviceOrderId
			    && (o.Deceased.UserId == scopeToUserId || o.FuneralHome.UserId == scopeToUserId));
			if (!visible)
				throw new UnauthorizedAccessException("Nemate pristup ovoj narudžbi.");
		}

		var payment = await _db.Payments
		    .Where(p => p.ServiceOrderId == serviceOrderId)
		    .OrderByDescending(p => p.Id)
		    .FirstOrDefaultAsync();

		if (payment == null)
		{
			return new PaymentStatusDto { ServiceOrderId = serviceOrderId, IsPaid = false, Status = "None" };
		}

		return new PaymentStatusDto
		{
			ServiceOrderId = serviceOrderId,
			IsPaid = payment.Status == PaymentStatus.Completed,
			Status = payment.Status.ToString(),
			Amount = payment.Amount,
			Currency = payment.Currency,
			CompletedAt = payment.CompletedAt,
				RefundedAt = payment.RefundedAt
		};
	}

	public async Task<PaymentStatusDto> RefundPaymentAsync(int serviceOrderId)
		{
			var payment = await _db.Payments
			    .Where(p => p.ServiceOrderId == serviceOrderId)
			    .OrderByDescending(p => p.Id)
			    .FirstOrDefaultAsync()
			    ?? throw new KeyNotFoundException("Plaćanje za ovu narudžbu nije pronađeno.");

			if (payment.Status == PaymentStatus.Refunded)
				throw new InvalidOperationException("Plaćanje je već refundirano.");

			if (payment.Status != PaymentStatus.Completed)
				throw new InvalidOperationException("Povrat je moguć samo za završeno plaćanje.");

			if (string.IsNullOrWhiteSpace(payment.PaypalCaptureId))
				throw new InvalidOperationException("Nedostaje PayPal identifikator naplate za povrat.");

			var (success, refundId) = await _payPalService.RefundCaptureAsync(
			    payment.PaypalCaptureId, payment.Amount, payment.Currency);

			if (!success)
				throw new InvalidOperationException("Povrat sredstava nije uspio. Molimo pokušajte ponovo.");

			payment.Status = PaymentStatus.Refunded;
			payment.PaypalRefundId = refundId;
			payment.RefundedAt = DateTime.UtcNow;
			await _db.SaveChangesAsync();

			_logger.LogInformation("Payment {PaymentId} for order {OrderId} refunded (PayPal refund {RefundId}).",
			    payment.Id, serviceOrderId, refundId);

			await NotifyServiceOrderOwnerAsync(serviceOrderId, "Povrat izvršen", "Izvršen je povrat sredstava za vašu pogrebnu uslugu.");

			return new PaymentStatusDto
			{
				ServiceOrderId = serviceOrderId,
				IsPaid = false,
				Status = payment.Status.ToString(),
				Amount = payment.Amount,
				Currency = payment.Currency,
				CompletedAt = payment.CompletedAt,
				RefundedAt = payment.RefundedAt
			};
		}

	private async Task AdvanceOrderAfterPaymentAsync(int serviceOrderId)
	{
		var order = await _db.ServiceOrders.FindAsync(serviceOrderId);
		if (order == null) return;

		if (!StatusTransitions.ServiceOrderAllows(order.Status, ServiceOrderStatus.InProgress)) return;

		order.Status = ServiceOrderStatus.InProgress;
		await _db.SaveChangesAsync();
	}

		private async Task PublishConfirmationAsync(PaymentEntity payment)
	{
		var order = await _db.ServiceOrders
		    .Include(o => o.Deceased)
		    .Include(o => o.ServiceType)
		    .Include(o => o.FuneralHome)
		    .FirstOrDefaultAsync(o => o.Id == payment.ServiceOrderId);

		if (order == null)
		{
			_logger.LogWarning("Payment {PaymentId} completed but service order {OrderId} was not found for confirmation email.",
			    payment.Id, payment.ServiceOrderId);
			return;
		}

		// the confirmation goes to the family and to the funeral home that will do the work
		var recipients = new List<(string Name, string Email)>();

		if (!string.IsNullOrWhiteSpace(order.Deceased?.ContactPersonEmail))
			recipients.Add((order.Deceased.ContactPersonName ?? string.Empty, order.Deceased.ContactPersonEmail));

		if (!string.IsNullOrWhiteSpace(order.FuneralHome?.Email))
			recipients.Add((order.FuneralHome.Name, order.FuneralHome.Email));

		if (recipients.Count == 0)
		{
			_logger.LogInformation("No contact email for order {OrderId}, skipping payment confirmation email.", order.Id);
			return;
		}

		foreach (var recipient in recipients)
		{
			await _publishEndpoint.Publish(new PaymentCompletedMessage(
			    payment.Id,
			    order.Id,
			    order.ServiceType?.Name ?? string.Empty,
			    payment.Amount,
			    payment.Currency,
			    recipient.Name,
			    recipient.Email,
			    payment.CompletedAt ?? DateTime.UtcNow
			));
		}

		if (order.FuneralHome?.UserId != null)
			await _notificationService.CreateAsync(order.FuneralHome.UserId, "Plaćanje zaprimljeno", "Narudžba pogrebne usluge je plaćena.");
	}

	private async Task NotifyServiceOrderOwnerAsync(int serviceOrderId, string title, string message)
		{
			var deceasedId = await _db.ServiceOrders
			    .Where(o => o.Id == serviceOrderId)
			    .Select(o => o.DeceasedId)
			    .FirstOrDefaultAsync();
			if (deceasedId > 0)
				await _notificationService.CreateForDeceasedAsync(deceasedId, title, message);
		}

		private decimal GetBamToEurRate()
	{
		if (decimal.TryParse(_configuration["PayPal:BamToEurRate"],
			   System.Globalization.NumberStyles.Any,
			   System.Globalization.CultureInfo.InvariantCulture,
			   out var rate) && rate > 0)
		{
			return rate;
		}
		return DefaultBamToEurRate;
	}
}
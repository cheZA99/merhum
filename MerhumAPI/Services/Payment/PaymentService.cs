using MassTransit;
using MerhumAPI.Data;
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

	public PaymentService(
	    ApplicationDbContext db,
	    IPayPalService payPalService,
	    IPublishEndpoint publishEndpoint,
	    IConfiguration configuration,
	    ILogger<PaymentService> logger)
	{
		_db = db;
		_payPalService = payPalService;
		_publishEndpoint = publishEndpoint;
		_configuration = configuration;
		_logger = logger;
	}

	public async Task<PaymentResponseDto> InitiatePaymentAsync(int serviceOrderId)
	{
		var order = await _db.ServiceOrders.FirstOrDefaultAsync(o => o.Id == serviceOrderId)
		    ?? throw new KeyNotFoundException("Narudžba nije pronađena.");

		var alreadyPaid = await _db.Payments
		    .AnyAsync(p => p.ServiceOrderId == serviceOrderId && p.Status == "Completed");
		if (alreadyPaid)
			throw new InvalidOperationException("Ova narudžba je već plaćena.");

		var eurAmount = Math.Round(order.Price / GetBamToEurRate(), 2, MidpointRounding.AwayFromZero);

		var payment = new PaymentEntity
		{
			ServiceOrderId = order.Id,
			Amount = eurAmount,
			Currency = "EUR",
			Status = "Pending"
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
			Status = payment.Status
		};
	}

	public async Task<bool> CompletePaymentAsync(string paypalOrderId)
	{
		var payment = await _db.Payments.FirstOrDefaultAsync(p => p.PaypalOrderId == paypalOrderId)
		    ?? throw new KeyNotFoundException("Plaćanje nije pronađeno.");

		if (payment.Status == "Completed")
			return true;

		var (success, captureId) = await _payPalService.CaptureOrderAsync(paypalOrderId);

		if (!success)
		{
			payment.Status = "Failed";
			await _db.SaveChangesAsync();
			return false;
		}

		payment.Status = "Completed";
		payment.PaypalCaptureId = captureId;
		payment.CompletedAt = DateTime.UtcNow;
		await _db.SaveChangesAsync();

		await PublishConfirmationAsync(payment);
		return true;
	}

	public async Task<PaymentStatusDto> GetStatusAsync(int serviceOrderId)
	{
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
			IsPaid = payment.Status == "Completed",
			Status = payment.Status,
			Amount = payment.Amount,
			Currency = payment.Currency,
			CompletedAt = payment.CompletedAt
		};
	}

	private async Task PublishConfirmationAsync(PaymentEntity payment)
	{
		var order = await _db.ServiceOrders
		    .Include(o => o.Deceased)
		    .Include(o => o.ServiceType)
		    .FirstOrDefaultAsync(o => o.Id == payment.ServiceOrderId);

		if (order == null)
		{
			_logger.LogWarning("Payment {PaymentId} completed but service order {OrderId} was not found for confirmation email.",
			    payment.Id, payment.ServiceOrderId);
			return;
		}

		var recipientEmail = order.Deceased?.ContactPersonEmail;
		var recipientName = order.Deceased?.ContactPersonName ?? string.Empty;

		if (string.IsNullOrWhiteSpace(recipientEmail))
		{
			_logger.LogInformation("No contact email for order {OrderId}, skipping payment confirmation email.", order.Id);
			return;
		}

		await _publishEndpoint.Publish(new PaymentCompletedMessage(
		    payment.Id,
		    order.Id,
		    order.ServiceType?.Name ?? string.Empty,
		    payment.Amount,
		    payment.Currency,
		    recipientName,
		    recipientEmail,
		    payment.CompletedAt ?? DateTime.UtcNow
		));
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
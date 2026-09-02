using MerhumAPI.DTOs.Payment;

namespace MerhumAPI.Services.Payment;

public interface IPaymentService
{
    Task<PaymentResponseDto> InitiatePaymentAsync(int serviceOrderId, string? scopeToUserId);
    Task<bool> CompletePaymentAsync(string paypalOrderId, string? scopeToUserId);
    Task<PaymentStatusDto> GetStatusAsync(int serviceOrderId, string? scopeToUserId);
    Task<PaymentStatusDto> RefundPaymentAsync(int serviceOrderId);
}

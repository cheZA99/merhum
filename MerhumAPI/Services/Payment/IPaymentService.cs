using MerhumAPI.DTOs.Payment;

namespace MerhumAPI.Services.Payment;

public interface IPaymentService
{
    Task<PaymentResponseDto> InitiatePaymentAsync(int serviceOrderId);
    Task<bool> CompletePaymentAsync(string paypalOrderId);
    Task<PaymentStatusDto> GetStatusAsync(int serviceOrderId);
}

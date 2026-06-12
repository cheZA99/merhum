namespace MerhumAPI.Services.Payment;

public interface IPayPalService
{
    Task<string> GetAccessTokenAsync();
    Task<(string orderId, string approvalUrl)> CreateOrderAsync(decimal amount, string currency);
    Task<(bool success, string captureId)> CaptureOrderAsync(string paypalOrderId);
}

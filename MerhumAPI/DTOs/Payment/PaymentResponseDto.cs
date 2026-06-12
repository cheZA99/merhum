namespace MerhumAPI.DTOs.Payment;

public class PaymentResponseDto
{
    public int PaymentId { get; set; }
    public string PaypalOrderId { get; set; } = string.Empty;
    public string ApprovalUrl { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
}

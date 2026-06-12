namespace MerhumAPI.DTOs.Payment;

public class PaymentStatusDto
{
    public int ServiceOrderId { get; set; }
    public bool IsPaid { get; set; }
    public string Status { get; set; } = "None"; // None / Pending / Completed / Failed / Cancelled
    public decimal? Amount { get; set; }
    public string? Currency { get; set; }
    public DateTime? CompletedAt { get; set; }
}

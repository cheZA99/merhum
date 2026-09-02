namespace MerhumAPI.DTOs.ServiceOrder;

public class ServiceOrderStatusRequest
{
    public string Status { get; set; } = string.Empty;
    public string? Reason { get; set; }
}

namespace MerhumAPI.DTOs.ServiceOrder;

public class ServiceOrderResponse
{
    public int Id { get; set; }
    public int DeceasedId { get; set; }
    public string DeceasedFullName { get; set; } = string.Empty;
    public int FuneralHomeId { get; set; }
    public string FuneralHomeName { get; set; } = string.Empty;
    public int ServiceTypeId { get; set; }
    public string ServiceTypeName { get; set; } = string.Empty;
    public decimal Price { get; set; }
    public string Status { get; set; } = string.Empty;
    public string? Note { get; set; }
    public DateTime OrderedAt { get; set; }
    public DateTime? CompletedAt { get; set; }
}

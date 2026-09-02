namespace MerhumAPI.DTOs.ServiceOffering;

public class ServiceOfferingResponse
{
    public int Id { get; set; }
    public int FuneralHomeId { get; set; }
    public string FuneralHomeName { get; set; } = string.Empty;
    public int ServiceTypeId { get; set; }
    public string ServiceTypeName { get; set; } = string.Empty;
    public decimal Price { get; set; }
    public string? Description { get; set; }
    public bool IsActive { get; set; }
}

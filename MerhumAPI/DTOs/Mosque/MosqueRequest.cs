namespace MerhumAPI.DTOs.Mosque;

public class MosqueRequest
{
    public string Name { get; set; } = string.Empty;
    public string Address { get; set; } = string.Empty;
    public int CityId { get; set; }
    public string? Phone { get; set; }
    public string? Email { get; set; }
    public int? Capacity { get; set; }
    public decimal? Latitude { get; set; }
    public decimal? Longitude { get; set; }
    public bool IsActive { get; set; } = true;
}

namespace MerhumAPI.DTOs.FuneralHome;

public class FuneralHomeResponse
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Address { get; set; } = string.Empty;
    public int CityId { get; set; }
    public string CityName { get; set; } = string.Empty;
    public string Phone { get; set; } = string.Empty;
    public string? Email { get; set; }
    public string? LicenseNumber { get; set; }
    public bool IsActive { get; set; }
}

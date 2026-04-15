namespace MerhumAPI.DTOs.Cemetery;

public class CemeteryResponse
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Address { get; set; } = string.Empty;
    public int CityId { get; set; }
    public string CityName { get; set; } = string.Empty;
    public int TotalPlaces { get; set; }
    public int OccupiedPlaces { get; set; }
    public int AvailablePlaces { get; set; }
    public int ReservedPlaces { get; set; }
    public double FillPercentage { get; set; }
    public decimal? Latitude { get; set; }
    public decimal? Longitude { get; set; }
    public bool IsActive { get; set; }
}

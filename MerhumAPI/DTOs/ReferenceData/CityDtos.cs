namespace MerhumAPI.DTOs.ReferenceData;

public class CityResponse
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? PostalCode { get; set; }
    public int CountryId { get; set; }
    public string CountryName { get; set; } = string.Empty;
}

public record CityRequest(string Name, string? PostalCode, int CountryId);

using System.ComponentModel.DataAnnotations;

namespace MerhumAPI.DTOs.ReferenceData;

public class CityResponse
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? PostalCode { get; set; }
    public int CountryId { get; set; }
    public string CountryName { get; set; } = string.Empty;
}

public record CityRequest(
    [property: Required(ErrorMessage = "Naziv je obavezan.")]
    [property: MaxLength(100)]
    string Name,
    [property: MaxLength(20)]
    string? PostalCode,
    [property: Range(1, int.MaxValue, ErrorMessage = "Odaberite državu.")]
    int CountryId);

using System.ComponentModel.DataAnnotations;

namespace MerhumAPI.DTOs.ReferenceData;

public class CemeterySectionResponse
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public int CemeteryId { get; set; }
}

public record SectionRequest(
    [property: Required(ErrorMessage = "Naziv je obavezan.")]
    [property: MaxLength(100)]
    string Name,
    [property: Range(1, int.MaxValue, ErrorMessage = "Odaberite mezarje.")]
    int CemeteryId);

using System.ComponentModel.DataAnnotations;

namespace MerhumAPI.DTOs.GraveSite;

public class GraveSiteRequest
{
    [Range(1, int.MaxValue, ErrorMessage = "Odaberite ispravnu stavku.")]
    public int CemeteryId { get; set; }
    public int? SectionId { get; set; }
    public string PlotNumber { get; set; } = string.Empty;
    public int? Row { get; set; }
    public decimal? Latitude { get; set; }
    public decimal? Longitude { get; set; }
}

public class AssignDeceasedRequest
{
    [Range(1, int.MaxValue, ErrorMessage = "Odaberite ispravnu stavku.")]
    public int DeceasedId { get; set; }
}

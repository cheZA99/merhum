namespace MerhumAPI.DTOs.GraveSite;

public class GraveSiteResponse
{
    public int Id { get; set; }
    public int CemeteryId { get; set; }
    public string CemeteryName { get; set; } = string.Empty;
    public int? SectionId { get; set; }
    public string? SectionName { get; set; }
    public string PlotNumber { get; set; } = string.Empty;
    public int? Row { get; set; }
    public string Status { get; set; } = string.Empty;
    public int? DeceasedId { get; set; }
    public string? DeceasedFullName { get; set; }
    public string? QrCodeUrl { get; set; }
    public decimal? Latitude { get; set; }
    public decimal? Longitude { get; set; }
}

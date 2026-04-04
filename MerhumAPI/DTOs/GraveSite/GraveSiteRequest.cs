namespace MerhumAPI.DTOs.GraveSite;

public class GraveSiteRequest
{
    public int CemeteryId { get; set; }
    public int? SectionId { get; set; }
    public string PlotNumber { get; set; } = string.Empty;
    public int? Row { get; set; }
    public decimal? Latitude { get; set; }
    public decimal? Longitude { get; set; }
}

public class AssignDeceasedRequest
{
    public int DeceasedId { get; set; }
}

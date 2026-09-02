namespace MerhumAPI.DTOs.ReferenceData;

public class CemeterySectionResponse
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public int CemeteryId { get; set; }
}

public record SectionRequest(string Name, int CemeteryId);

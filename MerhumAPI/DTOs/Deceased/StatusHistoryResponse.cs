namespace MerhumAPI.DTOs.Deceased;

public class StatusHistoryResponse
{
    public int Id { get; set; }
    public int DeceasedId { get; set; }
    public int StatusId { get; set; }
    public string StatusName { get; set; } = string.Empty;
    public string? Note { get; set; }
    public DateTime ChangedAt { get; set; }
    public string ChangedByUsername { get; set; } = string.Empty;
}

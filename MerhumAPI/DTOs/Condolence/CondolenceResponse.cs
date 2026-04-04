namespace MerhumAPI.DTOs.Condolence;

public class CondolenceResponse
{
    public int Id { get; set; }
    public int ObituaryId { get; set; }
    public string AuthorName { get; set; } = string.Empty;
    public string Text { get; set; } = string.Empty;
    public bool IsApproved { get; set; }
    public DateTime CreatedAt { get; set; }
}

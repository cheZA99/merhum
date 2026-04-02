namespace MerhumAPI.DTOs.Obituary;

public class ObituaryResponse
{
    public int Id { get; set; }
    public int DeceasedId { get; set; }
    public string DeceasedFullName { get; set; } = string.Empty;
    public string UniqueSlug { get; set; } = string.Empty;
    public string? QrCodeUrl { get; set; }
    public int ViewCount { get; set; }
    public bool IsPublic { get; set; }
    public bool IsActive { get; set; }
    public DateTime CreatedAt { get; set; }
    public List<CondolenceResponse> Condolences { get; set; } = new();
}

public class CondolenceResponse
{
    public int Id { get; set; }
    public string AuthorName { get; set; } = string.Empty;
    public string Text { get; set; } = string.Empty;
    public bool IsApproved { get; set; }
    public DateTime CreatedAt { get; set; }
}

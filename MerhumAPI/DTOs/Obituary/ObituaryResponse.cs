using MerhumAPI.DTOs.Condolence;

namespace MerhumAPI.DTOs.Obituary;

public class ObituaryResponse
{
    public int Id { get; set; }
    public int DeceasedId { get; set; }
    public string DeceasedFullName { get; set; } = string.Empty;
    public string? DeceasedPhotoUrl { get; set; }
    public DateOnly? DeceasedDateOfDeath { get; set; }
    public string UniqueSlug { get; set; } = string.Empty;
    public string? QrCodeUrl { get; set; }
    public int ViewCount { get; set; }
    public bool IsPublic { get; set; }
    public bool IsActive { get; set; }
    public DateTime CreatedAt { get; set; }
    public string? CreatedByUsername { get; set; }
    public int CondolenceCount { get; set; }
    public int ApprovedCondolenceCount { get; set; }
    public List<CondolenceResponse> Condolences { get; set; } = new();
}

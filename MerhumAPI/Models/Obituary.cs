using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace MerhumAPI.Models;

public class Obituary
{
    public int Id { get; set; }

    [ForeignKey(nameof(Deceased))]
    public int DeceasedId { get; set; }
    public Deceased Deceased { get; set; } = null!;

    [Required]
    [MaxLength(200)]
    public string UniqueSlug { get; set; } = string.Empty;

    [MaxLength(500)]
    public string? QrCodeUrl { get; set; }

    public int ViewCount { get; set; } = 0;

    public bool IsPublic { get; set; } = true;

    public bool IsActive { get; set; } = true;

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    [ForeignKey(nameof(CreatedByUser))]
    public string CreatedByUserId { get; set; } = string.Empty;
    public ApplicationUser CreatedByUser { get; set; } = null!;

    public ICollection<Condolence> Condolences { get; set; } = new List<Condolence>();
}

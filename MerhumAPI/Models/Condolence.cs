using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace MerhumAPI.Models;

public class Condolence
{
    public int Id { get; set; }

    [ForeignKey(nameof(Obituary))]
    public int ObituaryId { get; set; }
    public Obituary Obituary { get; set; } = null!;

    [Required]
    [MaxLength(150)]
    public string AuthorName { get; set; } = string.Empty;

    [Required]
    [MaxLength(1000)]
    public string Text { get; set; } = string.Empty;

    public bool IsApproved { get; set; } = false;

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    [ForeignKey(nameof(User))]
    public string? UserId { get; set; }
    public ApplicationUser? User { get; set; }
}

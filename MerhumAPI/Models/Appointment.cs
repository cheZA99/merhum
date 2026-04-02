using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace MerhumAPI.Models;

public class Appointment
{
    public int Id { get; set; }

    [ForeignKey(nameof(Deceased))]
    public int DeceasedId { get; set; }
    public Deceased Deceased { get; set; } = null!;

    [ForeignKey(nameof(Mosque))]
    public int MosqueId { get; set; }
    public Mosque Mosque { get; set; } = null!;

    [ForeignKey(nameof(Cemetery))]
    public int CemeteryId { get; set; }
    public Cemetery Cemetery { get; set; } = null!;

    [ForeignKey(nameof(Imam))]
    public int? ImamId { get; set; }
    public Imam? Imam { get; set; }

    [ForeignKey(nameof(GraveSite))]
    public int? GraveSiteId { get; set; }
    public GraveSite? GraveSite { get; set; }

    public DateTime FuneralDateTime { get; set; }

    [Required]
    [MaxLength(30)]
    public string Status { get; set; } = "Scheduled"; // Scheduled / Held / Cancelled

    [MaxLength(500)]
    public string? Note { get; set; }

    [ForeignKey(nameof(CreatedByUser))]
    public string CreatedByUserId { get; set; } = string.Empty;
    public ApplicationUser CreatedByUser { get; set; } = null!;

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}

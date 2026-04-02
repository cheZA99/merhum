using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace MerhumAPI.Models;

public class StatusHistory
{
    public int Id { get; set; }

    [ForeignKey(nameof(Deceased))]
    public int DeceasedId { get; set; }
    public Deceased Deceased { get; set; } = null!;

    [ForeignKey(nameof(ProcedureStatus))]
    public int StatusId { get; set; }
    public ProcedureStatus ProcedureStatus { get; set; } = null!;

    [MaxLength(500)]
    public string? Note { get; set; }

    public DateTime ChangedAt { get; set; } = DateTime.UtcNow;

    [ForeignKey(nameof(ChangedByUser))]
    public string ChangedByUserId { get; set; } = string.Empty;
    public ApplicationUser ChangedByUser { get; set; } = null!;
}

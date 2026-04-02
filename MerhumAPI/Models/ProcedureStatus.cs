using System.ComponentModel.DataAnnotations;

namespace MerhumAPI.Models;

public class ProcedureStatus
{
    public int Id { get; set; }

    [Required]
    [MaxLength(50)]
    public string Name { get; set; } = string.Empty;

    [MaxLength(200)]
    public string? Description { get; set; }

    public int SortOrder { get; set; }

    public ICollection<Deceased> Deceased { get; set; } = new List<Deceased>();
    public ICollection<StatusHistory> StatusHistories { get; set; } = new List<StatusHistory>();
}

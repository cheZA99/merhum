using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace MerhumAPI.Models;

public class ServiceOrder
{
    public int Id { get; set; }

    [ForeignKey(nameof(Deceased))]
    public int DeceasedId { get; set; }
    public Deceased Deceased { get; set; } = null!;

    [ForeignKey(nameof(FuneralHome))]
    public int FuneralHomeId { get; set; }
    public FuneralHome FuneralHome { get; set; } = null!;

    [ForeignKey(nameof(ServiceType))]
    public int ServiceTypeId { get; set; }
    public ServiceType ServiceType { get; set; } = null!;

    [Required]
    [Column(TypeName = "decimal(10,2)")]
    public decimal Price { get; set; }

    [Required]
    [MaxLength(20)]
    public string Status { get; set; } = "Ordered"; // Ordered / InProgress / Completed

    [MaxLength(500)]
    public string? Note { get; set; }

    public DateTime OrderedAt { get; set; } = DateTime.UtcNow;

    public DateTime? CompletedAt { get; set; }
}

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

    [ForeignKey(nameof(ServiceOffering))]
    public int? ServiceOfferingId { get; set; }
    public ServiceOffering? ServiceOffering { get; set; }

    // price charged, copied from the offering when the order is placed
    [Required]
    [Column(TypeName = "decimal(10,2)")]
    public decimal Price { get; set; }

    public ServiceOrderStatus Status { get; set; } = ServiceOrderStatus.Ordered;

    [MaxLength(500)]
    public string? Note { get; set; }

    public DateTime OrderedAt { get; set; } = DateTime.UtcNow;

    public DateTime? CompletedAt { get; set; }

    public DateTime? CancelledAt { get; set; }

    [ForeignKey(nameof(CancelledByUser))]
    public string? CancelledByUserId { get; set; }
    public ApplicationUser? CancelledByUser { get; set; }

    [MaxLength(500)]
    public string? CancellationReason { get; set; }
}

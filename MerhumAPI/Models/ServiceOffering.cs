using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace MerhumAPI.Models;

public class ServiceOffering
{
    public int Id { get; set; }

    [ForeignKey(nameof(FuneralHome))]
    public int FuneralHomeId { get; set; }
    public FuneralHome FuneralHome { get; set; } = null!;

    [ForeignKey(nameof(ServiceType))]
    public int ServiceTypeId { get; set; }
    public ServiceType ServiceType { get; set; } = null!;

    [Required]
    [Column(TypeName = "decimal(10,2)")]
    public decimal Price { get; set; }

    [MaxLength(500)]
    public string? Description { get; set; }

    public bool IsActive { get; set; } = true;

    public ICollection<ServiceOrder> ServiceOrders { get; set; } = new List<ServiceOrder>();
}

using System.ComponentModel.DataAnnotations;

namespace MerhumAPI.DTOs.ServiceOrder;

public class ServiceOrderRequest
{
    [Required]
    public int DeceasedId { get; set; }

    [Required]
    public int FuneralHomeId { get; set; }

    [Required]
    public int ServiceTypeId { get; set; }

    [Required]
    [Range(0.01, double.MaxValue)]
    public decimal Price { get; set; }

    [MaxLength(500)]
    public string? Note { get; set; }
}

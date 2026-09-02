using System.ComponentModel.DataAnnotations;

namespace MerhumAPI.DTOs.ServiceOrder;

public class ServiceOrderUpdateRequest
{
    [Required]
    public int DeceasedId { get; set; }

    [Required]
    public int ServiceOfferingId { get; set; }

    [MaxLength(500)]
    public string? Note { get; set; }
}

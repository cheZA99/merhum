using System.ComponentModel.DataAnnotations;

namespace MerhumAPI.DTOs.ServiceOrder;

public class ServiceOrderUpdateRequest
{
    [Required]
    [Range(1, int.MaxValue, ErrorMessage = "Odaberite ispravnu stavku.")]
    public int DeceasedId { get; set; }

    [Required]
    [Range(1, int.MaxValue, ErrorMessage = "Odaberite ispravnu stavku.")]
    public int ServiceOfferingId { get; set; }

    [MaxLength(500)]
    public string? Note { get; set; }
}

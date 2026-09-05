using System.ComponentModel.DataAnnotations;

namespace MerhumAPI.DTOs.ServiceOffering;

public class ServiceOfferingRequest
{
    [Required]
    [Range(1, int.MaxValue, ErrorMessage = "Odaberite ispravnu stavku.")]
    public int FuneralHomeId { get; set; }

    [Required]
    [Range(1, int.MaxValue, ErrorMessage = "Odaberite ispravnu stavku.")]
    public int ServiceTypeId { get; set; }

    [Required]
    [Range(0.01, double.MaxValue)]
    public decimal Price { get; set; }

    [MaxLength(500)]
    public string? Description { get; set; }

    public bool IsActive { get; set; } = true;
}

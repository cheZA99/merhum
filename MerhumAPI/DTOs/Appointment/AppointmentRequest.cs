using System.ComponentModel.DataAnnotations;

namespace MerhumAPI.DTOs.Appointment;

public class AppointmentRequest : IValidatableObject
{
    [Required]
    [Range(1, int.MaxValue, ErrorMessage = "Odaberite ispravnu stavku.")]
    public int DeceasedId { get; set; }

    [Required]
    [Range(1, int.MaxValue, ErrorMessage = "Odaberite ispravnu stavku.")]
    public int MosqueId { get; set; }

    [Required]
    [Range(1, int.MaxValue, ErrorMessage = "Odaberite ispravnu stavku.")]
    public int CemeteryId { get; set; }

    public int? ImamId { get; set; }

    public int? GraveSiteId { get; set; }

    [Required]
    public DateTime FuneralDateTime { get; set; }

    public IEnumerable<ValidationResult> Validate(ValidationContext validationContext)
    {
        if (FuneralDateTime < DateTime.UtcNow.AddYears(-5))
            yield return new ValidationResult("Termin je predaleko u prošlosti.", new[] { nameof(FuneralDateTime) });

        if (FuneralDateTime > DateTime.UtcNow.AddYears(2))
            yield return new ValidationResult("Termin je predaleko u budućnosti.", new[] { nameof(FuneralDateTime) });
    }

    [MaxLength(500)]
    public string? Note { get; set; }
}

using System.ComponentModel.DataAnnotations;

namespace MerhumAPI.DTOs.Deceased;

public class DeceasedRequest : IValidatableObject
{
    [Required, MaxLength(100)]
    public string FirstName { get; set; } = string.Empty;

    [Required, MaxLength(100)]
    public string LastName { get; set; } = string.Empty;

    [Required]
    public DateOnly DateOfBirth { get; set; }

    [Required]
    public DateOnly DateOfDeath { get; set; }

    [Required, MaxLength(200)]
    public string PlaceOfDeath { get; set; } = string.Empty;

    [MaxLength(500)]
    public string? PhotoUrl { get; set; }

    [Required, MaxLength(200)]
    public string ContactPersonName { get; set; } = string.Empty;

    [Required, MaxLength(20)]
    [Phone(ErrorMessage = "Broj telefona nije ispravan.")]
    public string ContactPersonPhone { get; set; } = string.Empty;

    [MaxLength(200), EmailAddress]
    public string? ContactPersonEmail { get; set; }

    [Required]
    [Range(1, int.MaxValue, ErrorMessage = "Odaberite ispravnu stavku.")]
    public int CityId { get; set; }

    [Required]
    [Range(1, int.MaxValue, ErrorMessage = "Odaberite ispravnu stavku.")]
    public int ProcedureStatusId { get; set; }

    public IEnumerable<ValidationResult> Validate(ValidationContext validationContext)
    {
        var today = DateOnly.FromDateTime(DateTime.UtcNow);

        if (DateOfDeath > today)
            yield return new ValidationResult("Datum smrti ne može biti u budućnosti.", new[] { nameof(DateOfDeath) });

        if (DateOfBirth > today)
            yield return new ValidationResult("Datum rođenja ne može biti u budućnosti.", new[] { nameof(DateOfBirth) });

        if (DateOfBirth < today.AddYears(-120))
            yield return new ValidationResult("Datum rođenja je predaleko u prošlosti.", new[] { nameof(DateOfBirth) });

        if (DateOfDeath < DateOfBirth)
            yield return new ValidationResult("Datum smrti ne može biti prije datuma rođenja.", new[] { nameof(DateOfDeath) });
    }
}

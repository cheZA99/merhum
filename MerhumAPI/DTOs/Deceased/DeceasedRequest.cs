using System.ComponentModel.DataAnnotations;

namespace MerhumAPI.DTOs.Deceased;

public class DeceasedRequest
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
    public string ContactPersonPhone { get; set; } = string.Empty;

    [MaxLength(200), EmailAddress]
    public string? ContactPersonEmail { get; set; }

    [Required]
    public int CityId { get; set; }

    [Required]
    public int ProcedureStatusId { get; set; }
}

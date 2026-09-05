using System.ComponentModel.DataAnnotations;

namespace MerhumAPI.DTOs.FuneralHome;

public class FuneralHomeRequest
{
    [Required(ErrorMessage = "Naziv je obavezan.")]
    [MaxLength(200)]
    public string Name { get; set; } = string.Empty;

    [Required(ErrorMessage = "Adresa je obavezna.")]
    [MaxLength(300)]
    public string Address { get; set; } = string.Empty;

    [Range(1, int.MaxValue, ErrorMessage = "Odaberite grad.")]
    public int CityId { get; set; }

    [Required(ErrorMessage = "Telefon je obavezan.")]
    [Phone(ErrorMessage = "Broj telefona nije ispravan.")]
    [MaxLength(20)]
    public string Phone { get; set; } = string.Empty;

    [EmailAddress(ErrorMessage = "Email adresa nije ispravna.")]
    [MaxLength(150)]
    public string? Email { get; set; }

    [MaxLength(100)]
    public string? LicenseNumber { get; set; }

    public bool IsActive { get; set; } = true;
}

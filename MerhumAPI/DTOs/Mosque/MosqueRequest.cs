using System.ComponentModel.DataAnnotations;

namespace MerhumAPI.DTOs.Mosque;

public class MosqueRequest
{
    [Required(ErrorMessage = "Naziv je obavezan.")]
    [MaxLength(200)]
    public string Name { get; set; } = string.Empty;

    [Required(ErrorMessage = "Adresa je obavezna.")]
    [MaxLength(300)]
    public string Address { get; set; } = string.Empty;

    [Range(1, int.MaxValue, ErrorMessage = "Odaberite grad.")]
    public int CityId { get; set; }

    [Phone(ErrorMessage = "Broj telefona nije ispravan.")]
    [MaxLength(20)]
    public string? Phone { get; set; }

    [EmailAddress(ErrorMessage = "Email adresa nije ispravna.")]
    [MaxLength(150)]
    public string? Email { get; set; }

    [Range(1, 100000, ErrorMessage = "Kapacitet mora biti veći od 0.")]
    public int? Capacity { get; set; }

    [Range(-90, 90, ErrorMessage = "Geografska širina mora biti između -90 i 90.")]
    public decimal? Latitude { get; set; }

    [Range(-180, 180, ErrorMessage = "Geografska dužina mora biti između -180 i 180.")]
    public decimal? Longitude { get; set; }

    public bool IsActive { get; set; } = true;
}

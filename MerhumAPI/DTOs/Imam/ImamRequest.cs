using System.ComponentModel.DataAnnotations;

namespace MerhumAPI.DTOs.Imam;

public class ImamRequest
{
    [Required(ErrorMessage = "Ime je obavezno.")]
    [MaxLength(100)]
    public string FirstName { get; set; } = string.Empty;

    [Required(ErrorMessage = "Prezime je obavezno.")]
    [MaxLength(100)]
    public string LastName { get; set; } = string.Empty;

    [Range(1, int.MaxValue, ErrorMessage = "Odaberite mesdžid.")]
    public int MosqueId { get; set; }

    [Required(ErrorMessage = "Telefon je obavezan.")]
    [Phone(ErrorMessage = "Broj telefona nije ispravan.")]
    [MaxLength(20)]
    public string Phone { get; set; } = string.Empty;

    [EmailAddress(ErrorMessage = "Email adresa nije ispravna.")]
    [MaxLength(150)]
    public string? Email { get; set; }

    public bool IsActive { get; set; } = true;
}

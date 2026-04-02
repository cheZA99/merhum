using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace MerhumAPI.Models;

public class City
{
    public int Id { get; set; }

    [Required]
    [MaxLength(150)]
    public string Name { get; set; } = string.Empty;

    [MaxLength(20)]
    public string? PostalCode { get; set; }

    [ForeignKey(nameof(Country))]
    public int CountryId { get; set; }
    public Country Country { get; set; } = null!;

    public ICollection<Deceased> Deceased { get; set; } = new List<Deceased>();
    public ICollection<Mosque> Mosques { get; set; } = new List<Mosque>();
    public ICollection<Cemetery> Cemeteries { get; set; } = new List<Cemetery>();
    public ICollection<FuneralHome> FuneralHomes { get; set; } = new List<FuneralHome>();
}

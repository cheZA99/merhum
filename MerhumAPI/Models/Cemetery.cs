using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace MerhumAPI.Models;

public class Cemetery
{
    public int Id { get; set; }

    [Required]
    [MaxLength(200)]
    public string Name { get; set; } = string.Empty;

    [Required]
    [MaxLength(300)]
    public string Address { get; set; } = string.Empty;

    [ForeignKey(nameof(City))]
    public int CityId { get; set; }
    public City City { get; set; } = null!;

    public int TotalPlaces { get; set; }

    [Column(TypeName = "decimal(10,7)")]
    public decimal? Latitude { get; set; }

    [Column(TypeName = "decimal(10,7)")]
    public decimal? Longitude { get; set; }

    public bool IsActive { get; set; } = true;

    public ICollection<CemeterySection> Sections { get; set; } = new List<CemeterySection>();
    public ICollection<GraveSite> GraveSites { get; set; } = new List<GraveSite>();
    public ICollection<Appointment> Appointments { get; set; } = new List<Appointment>();
}

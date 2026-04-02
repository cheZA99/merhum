using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace MerhumAPI.Models;

public class GraveSite
{
    public int Id { get; set; }

    [ForeignKey(nameof(Cemetery))]
    public int CemeteryId { get; set; }
    public Cemetery Cemetery { get; set; } = null!;

    [ForeignKey(nameof(Section))]
    public int? SectionId { get; set; }
    public CemeterySection? Section { get; set; }

    [Required]
    [MaxLength(20)]
    public string PlotNumber { get; set; } = string.Empty;

    public int? Row { get; set; }

    [Required]
    [MaxLength(20)]
    public string Status { get; set; } = "Available"; // Available / Occupied / Reserved

    [ForeignKey(nameof(Deceased))]
    public int? DeceasedId { get; set; }
    public Deceased? Deceased { get; set; }

    [MaxLength(500)]
    public string? QrCodeUrl { get; set; }

    [Column(TypeName = "decimal(10,7)")]
    public decimal? Latitude { get; set; }

    [Column(TypeName = "decimal(10,7)")]
    public decimal? Longitude { get; set; }
}

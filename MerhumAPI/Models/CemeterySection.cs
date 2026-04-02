using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace MerhumAPI.Models;

public class CemeterySection
{
    public int Id { get; set; }

    [Required]
    [MaxLength(100)]
    public string Name { get; set; } = string.Empty;

    [ForeignKey(nameof(Cemetery))]
    public int CemeteryId { get; set; }
    public Cemetery Cemetery { get; set; } = null!;

    public ICollection<GraveSite> GraveSites { get; set; } = new List<GraveSite>();
}

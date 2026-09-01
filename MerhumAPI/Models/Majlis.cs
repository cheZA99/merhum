using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace MerhumAPI.Models;

public class Majlis
{
    public int Id { get; set; }

    [Required]
    [MaxLength(150)]
    public string Name { get; set; } = string.Empty;

    [ForeignKey(nameof(Muftiate))]
    public int MuftiateId { get; set; }
    public Muftiate Muftiate { get; set; } = null!;

    public bool IsActive { get; set; } = true;

    public ICollection<Cemetery> Cemeteries { get; set; } = new List<Cemetery>();
}

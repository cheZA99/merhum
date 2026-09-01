using System.ComponentModel.DataAnnotations;

namespace MerhumAPI.Models;

public class Muftiate
{
    public int Id { get; set; }

    [Required]
    [MaxLength(150)]
    public string Name { get; set; } = string.Empty;

    public bool IsActive { get; set; } = true;

    public ICollection<Majlis> Majlises { get; set; } = new List<Majlis>();
}

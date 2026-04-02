using System.ComponentModel.DataAnnotations;

namespace MerhumAPI.Models;

public class Country
{
    public int Id { get; set; }

    [Required]
    [MaxLength(100)]
    public string Name { get; set; } = string.Empty;

    [Required]
    [MaxLength(10)]
    public string Code { get; set; } = string.Empty;

    public ICollection<City> Cities { get; set; } = new List<City>();
}

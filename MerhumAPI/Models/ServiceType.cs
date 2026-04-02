using System.ComponentModel.DataAnnotations;

namespace MerhumAPI.Models;

public class ServiceType
{
    public int Id { get; set; }

    [Required]
    [MaxLength(150)]
    public string Name { get; set; } = string.Empty;

    [MaxLength(500)]
    public string? Description { get; set; }

    public ICollection<ServiceOrder> ServiceOrders { get; set; } = new List<ServiceOrder>();
}

using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace MerhumAPI.Models;

public class Payment
{
    public int Id { get; set; }

    [ForeignKey(nameof(ServiceOrder))]
    public int ServiceOrderId { get; set; }
    public ServiceOrder ServiceOrder { get; set; } = null!;

    [Required]
    [Column(TypeName = "decimal(10,2)")]
    public decimal Amount { get; set; }

    [Required]
    [MaxLength(3)]
    public string Currency { get; set; } = "EUR";

    [MaxLength(100)]
    public string? PaypalOrderId { get; set; }

    [MaxLength(100)]
    public string? PaypalCaptureId { get; set; }

    [Required]
    [MaxLength(20)]
    public string Status { get; set; } = "Pending"; // Pending / Completed / Failed / Cancelled

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public DateTime? CompletedAt { get; set; }
}

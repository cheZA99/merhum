using System.ComponentModel.DataAnnotations;

namespace MerhumAPI.DTOs.Appointment;

public class AppointmentRequest
{
    [Required]
    public int DeceasedId { get; set; }

    [Required]
    public int MosqueId { get; set; }

    [Required]
    public int CemeteryId { get; set; }

    public int? ImamId { get; set; }

    public int? GraveSiteId { get; set; }

    [Required]
    public DateTime FuneralDateTime { get; set; }

    [MaxLength(500)]
    public string? Note { get; set; }
}

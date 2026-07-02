namespace MerhumAPI.DTOs.Appointment;

public class AppointmentResponse
{
    public int Id { get; set; }
    public int DeceasedId { get; set; }
    public string DeceasedFullName { get; set; } = string.Empty;
    public int? CityId { get; set; }
    public string? CityName { get; set; }
    public int MosqueId { get; set; }
    public string MosqueName { get; set; } = string.Empty;
    public int CemeteryId { get; set; }
    public string CemeteryName { get; set; } = string.Empty;
    public int? ImamId { get; set; }
    public string? ImamFullName { get; set; }
    public int? GraveSiteId { get; set; }
    public string? GravePlotNumber { get; set; }
    public DateTime FuneralDateTime { get; set; }
    public string Status { get; set; } = string.Empty;
    public string? Note { get; set; }
    public DateTime CreatedAt { get; set; }
}

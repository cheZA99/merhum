using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace MerhumAPI.Models;

public class Deceased
{
    public int Id { get; set; }

    [Required]
    [MaxLength(100)]
    public string FirstName { get; set; } = string.Empty;

    [Required]
    [MaxLength(100)]
    public string LastName { get; set; } = string.Empty;

    [Required]
    public DateOnly DateOfBirth { get; set; }

    [Required]
    public DateOnly DateOfDeath { get; set; }

    [Required]
    [MaxLength(200)]
    public string PlaceOfDeath { get; set; } = string.Empty;

    [MaxLength(500)]
    public string? PhotoUrl { get; set; }

    [Required]
    [MaxLength(200)]
    public string ContactPersonName { get; set; } = string.Empty;

    [Required]
    [MaxLength(20)]
    public string ContactPersonPhone { get; set; } = string.Empty;

    [MaxLength(200)]
    public string? ContactPersonEmail { get; set; }

    [ForeignKey(nameof(User))]
    public string UserId { get; set; } = string.Empty;
    public ApplicationUser User { get; set; } = null!;

    [ForeignKey(nameof(City))]
    public int CityId { get; set; }
    public City City { get; set; } = null!;

    [ForeignKey(nameof(ProcedureStatus))]
    public int ProcedureStatusId { get; set; }
    public ProcedureStatus ProcedureStatus { get; set; } = null!;

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public Obituary? Obituary { get; set; }
    public ICollection<StatusHistory> StatusHistories { get; set; } = new List<StatusHistory>();
    public ICollection<Appointment> Appointments { get; set; } = new List<Appointment>();
    public ICollection<ServiceOrder> ServiceOrders { get; set; } = new List<ServiceOrder>();
    public GraveSite? GraveSite { get; set; }
}

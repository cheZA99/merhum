namespace MerhumAPI.DTOs.Deceased;

public class DeceasedResponse
{
    public int Id { get; set; }
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
    public string FullName => $"{FirstName} {LastName}";
    public DateOnly DateOfBirth { get; set; }
    public DateOnly DateOfDeath { get; set; }
    public string PlaceOfDeath { get; set; } = string.Empty;
    public string? PhotoUrl { get; set; }
    public string ContactPersonName { get; set; } = string.Empty;
    public string ContactPersonPhone { get; set; } = string.Empty;
    public string? ContactPersonEmail { get; set; }
    public string CityName { get; set; } = string.Empty;
    public string CountryName { get; set; } = string.Empty;
    public string ProcedureStatusName { get; set; } = string.Empty;
    public int ProcedureStatusId { get; set; }
    public DateTime CreatedAt { get; set; }
    public string? ObituarySlug { get; set; }
}

namespace MerhumAPI.DTOs.User;

public class UserResponse
{
    public string Id { get; set; } = string.Empty;
    public string Username { get; set; } = string.Empty;
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
    public string FullName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string? Phone { get; set; }
    public string Role { get; set; } = string.Empty;
    public string? CityName { get; set; }
    public bool IsConfirmed { get; set; }
    public bool IsLocked { get; set; }
    public DateTime RegisteredAt { get; set; }
}

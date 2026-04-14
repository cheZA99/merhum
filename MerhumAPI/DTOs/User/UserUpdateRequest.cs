using System.ComponentModel.DataAnnotations;

namespace MerhumAPI.DTOs.User;

public class UserUpdateRequest
{
    [Required]
    [MaxLength(100)]
    public string FirstName { get; set; } = string.Empty;

    [Required]
    [MaxLength(100)]
    public string LastName { get; set; } = string.Empty;

    [Required]
    [EmailAddress]
    public string Email { get; set; } = string.Empty;

    [MaxLength(20)]
    public string? Phone { get; set; }

    public int? CityId { get; set; }

    [Required]
    public string Role { get; set; } = string.Empty;

    public string? NewPassword { get; set; }
}

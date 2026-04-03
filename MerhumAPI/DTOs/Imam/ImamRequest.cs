namespace MerhumAPI.DTOs.Imam;

public class ImamRequest
{
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
    public int MosqueId { get; set; }
    public string Phone { get; set; } = string.Empty;
    public string? Email { get; set; }
    public bool IsActive { get; set; } = true;
}

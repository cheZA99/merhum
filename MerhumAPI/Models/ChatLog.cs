using System.ComponentModel.DataAnnotations.Schema;

namespace MerhumAPI.Models;

public class ChatLog
{
    public int Id { get; set; }
    public string UserId { get; set; } = null!;
    public string Message { get; set; } = null!;
    public string Response { get; set; } = null!;
    public string? Context { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    [ForeignKey(nameof(UserId))]
    public ApplicationUser User { get; set; } = null!;
}

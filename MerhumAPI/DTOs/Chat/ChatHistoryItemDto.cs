namespace MerhumAPI.DTOs.Chat;

public class ChatHistoryItemDto
{
    public int Id { get; set; }
    public string Message { get; set; } = string.Empty;
    public string Response { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
}

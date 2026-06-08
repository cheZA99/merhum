namespace MerhumAPI.DTOs.Chat;

public class ChatResponseDto
{
    public string Response { get; set; } = string.Empty;
    public DateTime Timestamp { get; set; }
    public int ChatLogId { get; set; }
}

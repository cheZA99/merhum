using MerhumAPI.DTOs.Chat;

namespace MerhumAPI.Services.Chat;

public interface IChatService
{
    Task<ChatResponseDto> SendMessageAsync(string userId, string message);
    Task<List<ChatHistoryItemDto>> GetHistoryAsync(string userId, int pageNumber, int pageSize);
    Task<bool> ClearHistoryAsync(string userId);
}

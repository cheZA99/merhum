using MerhumAPI.Common;
using MerhumAPI.DTOs.Notification;

namespace MerhumAPI.Services;

public interface INotificationService
{
    Task CreateAsync(string userId, string title, string message);
    Task CreateForDeceasedAsync(int deceasedId, string title, string message);
    Task<PagedResponse<NotificationResponse>> GetForUserAsync(string userId, int pageNumber, int pageSize);
    Task<int> GetUnreadCountAsync(string userId);
    Task<bool> MarkReadAsync(int id, string userId);
    Task<int> MarkAllReadAsync(string userId);
}

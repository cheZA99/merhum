using MerhumAPI.Common;
using MerhumAPI.Data;
using MerhumAPI.DTOs.Notification;
using MerhumAPI.Models;
using Microsoft.EntityFrameworkCore;

namespace MerhumAPI.Services;

public class NotificationService : INotificationService
{
    private readonly ApplicationDbContext _db;

    public NotificationService(ApplicationDbContext db) => _db = db;

    public async Task CreateAsync(string userId, string title, string message)
    {
        if (string.IsNullOrEmpty(userId))
            return;

        _db.Notifications.Add(new Notification
        {
            UserId = userId,
            Title = title,
            Message = message
        });
        await _db.SaveChangesAsync();
    }

    public async Task CreateForDeceasedAsync(int deceasedId, string title, string message)
    {
        var userId = await _db.Deceased
            .Where(d => d.Id == deceasedId)
            .Select(d => d.UserId)
            .FirstOrDefaultAsync();

        await CreateAsync(userId ?? string.Empty, title, message);
    }

    public async Task<PagedResponse<NotificationResponse>> GetForUserAsync(string userId, int pageNumber, int pageSize)
    {
        (pageNumber, pageSize) = Pagination.Normalize(pageNumber, pageSize);

        var query = _db.Notifications
            .Where(n => n.UserId == userId)
            .OrderByDescending(n => n.CreatedAt);

        var total = await query.CountAsync();
        var items = await query
            .Skip((pageNumber - 1) * pageSize)
            .Take(pageSize)
            .Select(n => new NotificationResponse
            {
                Id = n.Id,
                Title = n.Title,
                Message = n.Message,
                IsRead = n.IsRead,
                CreatedAt = n.CreatedAt
            })
            .ToListAsync();

        return PagedResponse<NotificationResponse>.Create(items, total, pageNumber, pageSize);
    }

    public async Task<int> GetUnreadCountAsync(string userId) =>
        await _db.Notifications.CountAsync(n => n.UserId == userId && !n.IsRead);

    public async Task<bool> MarkReadAsync(int id, string userId)
    {
        var notification = await _db.Notifications
            .FirstOrDefaultAsync(n => n.Id == id && n.UserId == userId);
        if (notification == null)
            return false;

        if (!notification.IsRead)
        {
            notification.IsRead = true;
            await _db.SaveChangesAsync();
        }
        return true;
    }

    public async Task<int> MarkAllReadAsync(string userId)
    {
        var unread = await _db.Notifications
            .Where(n => n.UserId == userId && !n.IsRead)
            .ToListAsync();

        foreach (var n in unread)
            n.IsRead = true;

        if (unread.Count > 0)
            await _db.SaveChangesAsync();

        return unread.Count;
    }
}

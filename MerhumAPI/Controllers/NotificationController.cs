using System.Security.Claims;
using MerhumAPI.Common;
using MerhumAPI.DTOs.Notification;
using MerhumAPI.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace MerhumAPI.Controllers;

[ApiController]
[Route("api/notifikacije")]
[Authorize]
public class NotificationController : ControllerBase
{
    private readonly INotificationService _notificationService;

    public NotificationController(INotificationService notificationService) =>
        _notificationService = notificationService;

    private string UserId => User.FindFirstValue(ClaimTypes.NameIdentifier)
        ?? User.FindFirstValue("sub")
        ?? throw new UnauthorizedAccessException();

    [HttpGet]
    public async Task<ActionResult<PagedResponse<NotificationResponse>>> GetMy(
        [FromQuery] int pageNumber = 1,
        [FromQuery] int pageSize = 20)
    {
        var result = await _notificationService.GetForUserAsync(UserId, pageNumber, pageSize);
        return Ok(result);
    }

    [HttpGet("nepregledano")]
    public async Task<ActionResult<ApiResponse<int>>> UnreadCount()
    {
        var count = await _notificationService.GetUnreadCountAsync(UserId);
        return Ok(ApiResponse<int>.Ok(count));
    }

    [HttpPut("{id:int}/procitano")]
    public async Task<IActionResult> MarkRead(int id)
    {
        var ok = await _notificationService.MarkReadAsync(id, UserId);
        if (!ok) return NotFound(ApiResponse<object>.Fail("Notifikacija nije pronađena."));
        return NoContent();
    }

    [HttpPut("procitano-sve")]
    public async Task<ActionResult<ApiResponse<object>>> MarkAllRead()
    {
        var count = await _notificationService.MarkAllReadAsync(UserId);
        return Ok(ApiResponse<object>.Ok(new { updated = count }, "Sve notifikacije označene kao pročitane."));
    }
}

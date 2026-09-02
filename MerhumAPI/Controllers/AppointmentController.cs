using MerhumAPI.Common;
using MerhumAPI.DTOs.Appointment;
using MerhumAPI.Models;
using MerhumAPI.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace MerhumAPI.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class AppointmentController : ControllerBase
{
    private readonly IAppointmentService _appointmentService;

    public AppointmentController(IAppointmentService appointmentService) => _appointmentService = appointmentService;

    [HttpGet]
    public async Task<ActionResult<PagedResponse<AppointmentResponse>>> GetAll(
        [FromQuery] int? deceasedId,
        [FromQuery] AppointmentStatus? status,
        [FromQuery] int? mosqueId,
        [FromQuery] int? imamId,
        [FromQuery] int? cityId,
        [FromQuery] DateTime? dateFrom,
        [FromQuery] DateTime? dateTo,
        [FromQuery] int pageNumber = 1,
        [FromQuery] int pageSize = 20)
    {
        var scope = User.IsAdministrator() ? null : User.GetUserId();
        var result = await _appointmentService.GetAllAsync(deceasedId, status, mosqueId, imamId, cityId, dateFrom, dateTo, pageNumber, pageSize, scope);
        return Ok(result);
    }

    // upcoming scheduled funerals, also used by the imam screen (no per-imam link yet)
    [HttpGet("upcoming")]
    [AllowAnonymous]
    public async Task<ActionResult<List<AppointmentResponse>>> Upcoming([FromQuery] int? cityId)
    {
        var result = await _appointmentService.GetAllAsync(
            null, AppointmentStatus.Scheduled, null, null, cityId, DateTime.UtcNow, null, 1, 200, null);
        return Ok(result.Data);
    }

    [HttpGet("{id:int}")]
    public async Task<ActionResult<ApiResponse<AppointmentResponse>>> GetById(int id)
    {
        var appointment = await _appointmentService.GetByIdAsync(id, User.IsAdministrator() ? null : User.GetUserId());
        if (appointment == null) return NotFound(ApiResponse<AppointmentResponse>.Fail("Appointment not found."));
        return Ok(ApiResponse<AppointmentResponse>.Ok(appointment));
    }

    [HttpPost]
    [Authorize(Policy = "MobileAccess")]
    public async Task<ActionResult<ApiResponse<AppointmentResponse>>> Create([FromBody] AppointmentRequest request)
    {
        var appointment = await _appointmentService.CreateAsync(request, User.GetUserId());
        return CreatedAtAction(nameof(GetById), new { id = appointment.Id }, ApiResponse<AppointmentResponse>.Ok(appointment));
    }

    [HttpPut("{id:int}")]
    [Authorize(Policy = "DesktopAccess")]
    public async Task<ActionResult<ApiResponse<AppointmentResponse>>> Update(int id, [FromBody] AppointmentRequest request)
    {
        var updated = await _appointmentService.UpdateAsync(id, request);
        if (updated == null) return NotFound(ApiResponse<AppointmentResponse>.Fail("Appointment not found."));
        return Ok(ApiResponse<AppointmentResponse>.Ok(updated));
    }

    [HttpPatch("{id:int}/status")]
    [Authorize(Policy = "DesktopAccess")]
    public async Task<IActionResult> UpdateStatus(int id, [FromBody] AppointmentStatusRequest request)
    {
        if (!Enum.TryParse<AppointmentStatus>(request.Status, ignoreCase: true, out var target))
            return BadRequest(ApiResponse<object>.Fail("Nepoznat status termina."));

        var result = await _appointmentService.UpdateStatusAsync(id, target, User.GetUserId(), request.Reason);
        return StatusResult(result);
    }

    // cancels the appointment instead of removing it, so the audit trail survives
    [HttpDelete("{id:int}")]
    [Authorize(Policy = "AdminOnly")]
    public async Task<IActionResult> Cancel(int id, [FromQuery] string? reason)
    {
        var result = await _appointmentService.UpdateStatusAsync(id, AppointmentStatus.Cancelled, User.GetUserId(), reason);
        return StatusResult(result);
    }

    private IActionResult StatusResult(StatusChangeResult result) => result switch
    {
        StatusChangeResult.NotFound => NotFound(ApiResponse<object>.Fail("Appointment not found.")),
        StatusChangeResult.NotAllowed => BadRequest(ApiResponse<object>.Fail("Tražena promjena statusa nije dozvoljena.")),
        StatusChangeResult.Forbidden => Forbid(),
        _ => NoContent()
    };
}

public class AppointmentStatusRequest
{
    public string Status { get; set; } = string.Empty;
    public string? Reason { get; set; }
}

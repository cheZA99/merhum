using MerhumAPI.Common;
using MerhumAPI.DTOs.Appointment;
using MerhumAPI.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace MerhumAPI.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class AppointmentController : ControllerBase
{
    private readonly IAppointmentService _appointmentService;

    public AppointmentController(IAppointmentService appointmentService) => _appointmentService = appointmentService;

    [HttpGet]
    [Authorize(Policy = "DesktopAccess")]
    public async Task<ActionResult<PagedResponse<AppointmentResponse>>> GetAll(
        [FromQuery] int? deceasedId,
        [FromQuery] string? status,
        [FromQuery] int? mosqueId,
        [FromQuery] int? imamId,
        [FromQuery] int? cityId,
        [FromQuery] DateTime? dateFrom,
        [FromQuery] DateTime? dateTo,
        [FromQuery] int pageNumber = 1,
        [FromQuery] int pageSize = 20)
    {
        var result = await _appointmentService.GetAllAsync(deceasedId, status, mosqueId, imamId, cityId, dateFrom, dateTo, pageNumber, pageSize);
        return Ok(result);
    }

    // upcoming scheduled funerals, also used by the imam screen (no per-imam link yet)
    [HttpGet("upcoming")]
    [AllowAnonymous]
    public async Task<ActionResult<List<AppointmentResponse>>> Upcoming([FromQuery] int? cityId)
    {
        var result = await _appointmentService.GetAllAsync(
            null, "Scheduled", null, null, cityId, DateTime.UtcNow, null, 1, 200);
        return Ok(result.Data);
    }

    [HttpGet("{id:int}")]
    public async Task<ActionResult<ApiResponse<AppointmentResponse>>> GetById(int id)
    {
        var appointment = await _appointmentService.GetByIdAsync(id);
        if (appointment == null) return NotFound(ApiResponse<AppointmentResponse>.Fail("Appointment not found."));
        return Ok(ApiResponse<AppointmentResponse>.Ok(appointment));
    }

    [HttpPost]
    [Authorize(Policy = "DesktopAccess")]
    public async Task<ActionResult<ApiResponse<AppointmentResponse>>> Create([FromBody] AppointmentRequest request)
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier)
                  ?? User.FindFirstValue("sub")
                  ?? throw new UnauthorizedAccessException();

        var appointment = await _appointmentService.CreateAsync(request, userId);
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
        var updated = await _appointmentService.UpdateStatusAsync(id, request.Status);
        if (!updated) return NotFound(ApiResponse<object>.Fail("Appointment not found."));
        return NoContent();
    }

    [HttpDelete("{id:int}")]
    [Authorize(Policy = "AdminOnly")]
    public async Task<IActionResult> Delete(int id)
    {
        var deleted = await _appointmentService.DeleteAsync(id);
        if (!deleted) return NotFound(ApiResponse<object>.Fail("Appointment not found."));
        return NoContent();
    }
}

public class AppointmentStatusRequest
{
    public string Status { get; set; } = string.Empty;
}

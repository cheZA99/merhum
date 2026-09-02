using MerhumAPI.Common;
using MerhumAPI.DTOs.ServiceOrder;
using MerhumAPI.Models;
using MerhumAPI.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace MerhumAPI.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class ServiceOrderController : ControllerBase
{
    private readonly IServiceOrderService _serviceOrderService;

    public ServiceOrderController(IServiceOrderService serviceOrderService) => _serviceOrderService = serviceOrderService;

    [HttpGet]
    [Authorize(Roles = "Porodica,JavniKorisnik,PogrebnoPreduzeće,Administrator")]
    public async Task<ActionResult<PagedResponse<ServiceOrderResponse>>> GetAll(
        [FromQuery] int? deceasedId,
        [FromQuery] ServiceOrderStatus? status,
        [FromQuery] int? funeralHomeId,
        [FromQuery] DateTime? dateFrom,
        [FromQuery] DateTime? dateTo,
        [FromQuery] int pageNumber = 1,
        [FromQuery] int pageSize = 20)
    {
        var scope = User.IsAdministrator() ? null : User.GetUserId();
        var result = await _serviceOrderService.GetAllAsync(deceasedId, status, funeralHomeId, dateFrom, dateTo, pageNumber, pageSize, scope);
        return Ok(result);
    }

    [HttpGet("{id:int}")]
    public async Task<ActionResult<ApiResponse<ServiceOrderResponse>>> GetById(int id)
    {
        var order = await _serviceOrderService.GetByIdAsync(id, User.IsAdministrator() ? null : User.GetUserId());
        if (order == null) return NotFound(ApiResponse<ServiceOrderResponse>.Fail("Service order not found."));
        return Ok(ApiResponse<ServiceOrderResponse>.Ok(order));
    }

    [HttpPost]
    [Authorize(Policy = "MobileAccess")]
    public async Task<ActionResult<ApiResponse<ServiceOrderResponse>>> Create([FromBody] ServiceOrderRequest request)
    {
        var order = await _serviceOrderService.CreateAsync(request, User.IsAdministrator() ? null : User.GetUserId());
        if (order == null) return NotFound(ApiResponse<ServiceOrderResponse>.Fail("Deceased not found."));
        return CreatedAtAction(nameof(GetById), new { id = order.Id }, ApiResponse<ServiceOrderResponse>.Ok(order));
    }

    [HttpPut("{id:int}")]
    [Authorize(Policy = "DesktopAccess")]
    public async Task<ActionResult<ApiResponse<ServiceOrderResponse>>> Update(int id, [FromBody] ServiceOrderUpdateRequest request)
    {
        var updated = await _serviceOrderService.UpdateAsync(id, request);
        if (updated == null) return NotFound(ApiResponse<ServiceOrderResponse>.Fail("Service order not found."));
        return Ok(ApiResponse<ServiceOrderResponse>.Ok(updated));
    }

    [HttpPatch("{id:int}/status")]
    [Authorize(Policy = "PogrebnoAccess")]
    public async Task<IActionResult> UpdateStatus(int id, [FromBody] ServiceOrderStatusRequest request)
    {
        if (!Enum.TryParse<ServiceOrderStatus>(request.Status, ignoreCase: true, out var target))
            return BadRequest(ApiResponse<object>.Fail("Nepoznat status narudžbe."));

        var scope = User.IsAdministrator() ? null : User.GetUserId();
        var result = await _serviceOrderService.UpdateStatusAsync(id, target, User.GetUserId(), request.Reason, scope);
        return StatusResult(result);
    }

    // cancels the order instead of removing it, so the audit trail survives
    [HttpDelete("{id:int}")]
    [Authorize(Policy = "AdminOnly")]
    public async Task<IActionResult> Cancel(int id, [FromQuery] string? reason)
    {
        var result = await _serviceOrderService.UpdateStatusAsync(id, ServiceOrderStatus.Cancelled, User.GetUserId(), reason, null);
        return StatusResult(result);
    }

    private IActionResult StatusResult(StatusChangeResult result) => result switch
    {
        StatusChangeResult.NotFound => NotFound(ApiResponse<object>.Fail("Service order not found.")),
        StatusChangeResult.NotAllowed => BadRequest(ApiResponse<object>.Fail("Tražena promjena statusa nije dozvoljena.")),
        StatusChangeResult.Forbidden => Forbid(),
        _ => NoContent()
    };
}

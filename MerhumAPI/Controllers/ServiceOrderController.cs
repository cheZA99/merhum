using MerhumAPI.Common;
using MerhumAPI.DTOs.ServiceOrder;
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
    [Authorize(Policy = "DesktopAccess")]
    public async Task<ActionResult<PagedResponse<ServiceOrderResponse>>> GetAll(
        [FromQuery] int? deceasedId,
        [FromQuery] string? status,
        [FromQuery] int pageNumber = 1,
        [FromQuery] int pageSize = 20)
    {
        var result = await _serviceOrderService.GetAllAsync(deceasedId, status, pageNumber, pageSize);
        return Ok(result);
    }

    [HttpGet("{id:int}")]
    [Authorize(Policy = "DesktopAccess")]
    public async Task<ActionResult<ApiResponse<ServiceOrderResponse>>> GetById(int id)
    {
        var order = await _serviceOrderService.GetByIdAsync(id);
        if (order == null) return NotFound(ApiResponse<ServiceOrderResponse>.Fail("Service order not found."));
        return Ok(ApiResponse<ServiceOrderResponse>.Ok(order));
    }

    [HttpPost]
    [Authorize(Policy = "DesktopAccess")]
    public async Task<ActionResult<ApiResponse<ServiceOrderResponse>>> Create([FromBody] ServiceOrderRequest request)
    {
        var order = await _serviceOrderService.CreateAsync(request);
        return CreatedAtAction(nameof(GetById), new { id = order.Id }, ApiResponse<ServiceOrderResponse>.Ok(order));
    }

    [HttpPatch("{id:int}/status")]
    [Authorize(Policy = "PogrebnoAccess")]
    public async Task<IActionResult> UpdateStatus(int id, [FromBody] ServiceOrderStatusRequest request)
    {
        var updated = await _serviceOrderService.UpdateStatusAsync(id, request.Status);
        if (!updated) return NotFound(ApiResponse<object>.Fail("Service order not found."));
        return NoContent();
    }

    [HttpDelete("{id:int}")]
    [Authorize(Policy = "AdminOnly")]
    public async Task<IActionResult> Delete(int id)
    {
        var deleted = await _serviceOrderService.DeleteAsync(id);
        if (!deleted) return NotFound(ApiResponse<object>.Fail("Service order not found."));
        return NoContent();
    }
}

using MerhumAPI.Common;
using MerhumAPI.DTOs.ServiceOffering;
using MerhumAPI.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace MerhumAPI.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class ServiceOfferingController : ControllerBase
{
    private readonly IServiceOfferingService _serviceOfferingService;

    public ServiceOfferingController(IServiceOfferingService serviceOfferingService) => _serviceOfferingService = serviceOfferingService;

    [HttpGet]
    public async Task<ActionResult<PagedResponse<ServiceOfferingResponse>>> GetAll(
        [FromQuery] int? funeralHomeId,
        [FromQuery] bool activeOnly = true,
        [FromQuery] int pageNumber = 1,
        [FromQuery] int pageSize = 20)
    {
        var result = await _serviceOfferingService.GetAllAsync(funeralHomeId, activeOnly, pageNumber, pageSize);
        return Ok(result);
    }

    [HttpGet("{id:int}")]
    public async Task<ActionResult<ApiResponse<ServiceOfferingResponse>>> GetById(int id)
    {
        var offering = await _serviceOfferingService.GetByIdAsync(id);
        if (offering == null) return NotFound(ApiResponse<ServiceOfferingResponse>.Fail("Service offering not found."));
        return Ok(ApiResponse<ServiceOfferingResponse>.Ok(offering));
    }

    [HttpPost]
    [Authorize(Policy = "AdminOnly")]
    public async Task<ActionResult<ApiResponse<ServiceOfferingResponse>>> Create([FromBody] ServiceOfferingRequest request)
    {
        var offering = await _serviceOfferingService.CreateAsync(request);
        return CreatedAtAction(nameof(GetById), new { id = offering.Id }, ApiResponse<ServiceOfferingResponse>.Ok(offering));
    }

    [HttpPut("{id:int}")]
    [Authorize(Policy = "AdminOnly")]
    public async Task<ActionResult<ApiResponse<ServiceOfferingResponse>>> Update(int id, [FromBody] ServiceOfferingRequest request)
    {
        var updated = await _serviceOfferingService.UpdateAsync(id, request);
        if (updated == null) return NotFound(ApiResponse<ServiceOfferingResponse>.Fail("Service offering not found."));
        return Ok(ApiResponse<ServiceOfferingResponse>.Ok(updated));
    }

    [HttpDelete("{id:int}")]
    [Authorize(Policy = "AdminOnly")]
    public async Task<IActionResult> Delete(int id)
    {
        var deleted = await _serviceOfferingService.DeleteAsync(id);
        if (!deleted) return NotFound(ApiResponse<object>.Fail("Service offering not found."));
        return NoContent();
    }
}

using MerhumAPI.Common;
using MerhumAPI.DTOs.Cemetery;
using MerhumAPI.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace MerhumAPI.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class CemeteryController : ControllerBase
{
    private readonly ICemeteryService _cemeteryService;

    public CemeteryController(ICemeteryService cemeteryService) => _cemeteryService = cemeteryService;

    [HttpGet]
    public async Task<ActionResult<PagedResponse<CemeteryResponse>>> GetAll(
        [FromQuery] string? search,
        [FromQuery] int pageNumber = 1,
        [FromQuery] int pageSize = 20)
    {
        var result = await _cemeteryService.GetAllAsync(search, pageNumber, pageSize);
        return Ok(result);
    }

    [HttpGet("{id:int}")]
    public async Task<ActionResult<ApiResponse<CemeteryResponse>>> GetById(int id)
    {
        var cemetery = await _cemeteryService.GetByIdAsync(id);
        if (cemetery == null) return NotFound(ApiResponse<CemeteryResponse>.Fail("Cemetery not found."));
        return Ok(ApiResponse<CemeteryResponse>.Ok(cemetery));
    }

    [HttpPost]
    [Authorize(Policy = "AdminOnly")]
    public async Task<ActionResult<ApiResponse<CemeteryResponse>>> Create([FromBody] CemeteryRequest request)
    {
        var cemetery = await _cemeteryService.CreateAsync(request);
        return CreatedAtAction(nameof(GetById), new { id = cemetery.Id }, ApiResponse<CemeteryResponse>.Ok(cemetery));
    }

    [HttpPut("{id:int}")]
    [Authorize(Policy = "AdminOnly")]
    public async Task<IActionResult> Update(int id, [FromBody] CemeteryRequest request)
    {
        var updated = await _cemeteryService.UpdateAsync(id, request);
        if (!updated) return NotFound(ApiResponse<object>.Fail("Cemetery not found."));
        return NoContent();
    }

    [HttpDelete("{id:int}")]
    [Authorize(Policy = "AdminOnly")]
    public async Task<IActionResult> Delete(int id)
    {
        var deleted = await _cemeteryService.DeleteAsync(id);
        if (!deleted) return NotFound(ApiResponse<object>.Fail("Cemetery not found."));
        return NoContent();
    }
}

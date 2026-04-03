using MerhumAPI.Common;
using MerhumAPI.DTOs.Mosque;
using MerhumAPI.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace MerhumAPI.Controllers;

[ApiController]
[Route("api/[controller]")]
public class MosqueController : ControllerBase
{
    private readonly IMosqueService _mosqueService;

    public MosqueController(IMosqueService mosqueService) => _mosqueService = mosqueService;

    [HttpGet]
    [AllowAnonymous]
    public async Task<ActionResult<PagedResponse<MosqueResponse>>> GetAll(
        [FromQuery] string? search,
        [FromQuery] int pageNumber = 1,
        [FromQuery] int pageSize = 20)
    {
        var result = await _mosqueService.GetAllAsync(search, pageNumber, pageSize);
        return Ok(result);
    }

    [HttpGet("{id:int}")]
    [AllowAnonymous]
    public async Task<ActionResult<ApiResponse<MosqueResponse>>> GetById(int id)
    {
        var mosque = await _mosqueService.GetByIdAsync(id);
        if (mosque == null) return NotFound(ApiResponse<MosqueResponse>.Fail("Mosque not found."));
        return Ok(ApiResponse<MosqueResponse>.Ok(mosque));
    }

    [HttpPost]
    [Authorize(Policy = "AdminOnly")]
    public async Task<ActionResult<ApiResponse<MosqueResponse>>> Create([FromBody] MosqueRequest request)
    {
        var mosque = await _mosqueService.CreateAsync(request);
        return CreatedAtAction(nameof(GetById), new { id = mosque.Id }, ApiResponse<MosqueResponse>.Ok(mosque));
    }

    [HttpPut("{id:int}")]
    [Authorize(Policy = "AdminOnly")]
    public async Task<IActionResult> Update(int id, [FromBody] MosqueRequest request)
    {
        var updated = await _mosqueService.UpdateAsync(id, request);
        if (!updated) return NotFound(ApiResponse<object>.Fail("Mosque not found."));
        return NoContent();
    }

    [HttpDelete("{id:int}")]
    [Authorize(Policy = "AdminOnly")]
    public async Task<IActionResult> Delete(int id)
    {
        var deleted = await _mosqueService.DeleteAsync(id);
        if (!deleted) return NotFound(ApiResponse<object>.Fail("Mosque not found."));
        return NoContent();
    }
}

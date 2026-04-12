using MerhumAPI.Common;
using MerhumAPI.DTOs.Obituary;
using MerhumAPI.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace MerhumAPI.Controllers;

[ApiController]
[Route("api/[controller]")]
public class ObituaryController : ControllerBase
{
    private readonly IObituaryService _obituaryService;

    public ObituaryController(IObituaryService obituaryService) => _obituaryService = obituaryService;

    [HttpGet]
    [Authorize(Policy = "DesktopAccess")]
    public async Task<ActionResult<PagedResponse<ObituaryResponse>>> GetAll(
        [FromQuery] bool? isPublic,
        [FromQuery] bool? isActive,
        [FromQuery] string? deceasedName,
        [FromQuery] int pageNumber = 1,
        [FromQuery] int pageSize = 20)
    {
        var result = await _obituaryService.GetAllAsync(isPublic, isActive, deceasedName, pageNumber, pageSize);
        return Ok(result);
    }

    [HttpGet("{id:int}")]
    [Authorize(Policy = "DesktopAccess")]
    public async Task<ActionResult<ApiResponse<ObituaryResponse>>> GetById(int id)
    {
        var obituary = await _obituaryService.GetByIdAsync(id);
        if (obituary == null) return NotFound(ApiResponse<ObituaryResponse>.Fail("Obituary not found."));
        return Ok(ApiResponse<ObituaryResponse>.Ok(obituary));
    }

    [HttpGet("slug/{slug}")]
    [AllowAnonymous]
    public async Task<ActionResult<ApiResponse<ObituaryResponse>>> GetBySlug(string slug)
    {
        var obituary = await _obituaryService.GetBySlugAsync(slug);
        if (obituary == null) return NotFound(ApiResponse<ObituaryResponse>.Fail("Obituary not found."));

        await _obituaryService.IncrementViewCountAsync(obituary.Id);
        return Ok(ApiResponse<ObituaryResponse>.Ok(obituary));
    }

    [HttpPost]
    [Authorize(Policy = "DesktopAccess")]
    public async Task<ActionResult<ApiResponse<ObituaryResponse>>> Create([FromBody] ObituaryRequest request)
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier)
                  ?? User.FindFirstValue("sub")
                  ?? throw new UnauthorizedAccessException();

        var obituary = await _obituaryService.CreateAsync(request.DeceasedId, request.IsPublic, userId);
        return CreatedAtAction(nameof(GetBySlug), new { slug = obituary.UniqueSlug }, ApiResponse<ObituaryResponse>.Ok(obituary));
    }

    [HttpPut("{id:int}")]
    [Authorize(Policy = "DesktopAccess")]
    public async Task<IActionResult> Update(int id, [FromBody] ObituaryUpdateRequest request)
    {
        var updated = await _obituaryService.UpdateAsync(id, request.IsPublic, request.IsActive);
        if (!updated) return NotFound(ApiResponse<object>.Fail("Obituary not found."));
        return NoContent();
    }

    [HttpDelete("{id:int}")]
    [Authorize(Policy = "AdminOnly")]
    public async Task<IActionResult> Delete(int id)
    {
        var deleted = await _obituaryService.DeleteAsync(id);
        if (!deleted) return NotFound(ApiResponse<object>.Fail("Obituary not found."));
        return NoContent();
    }
}

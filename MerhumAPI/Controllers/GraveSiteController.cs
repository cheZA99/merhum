using MerhumAPI.Common;
using MerhumAPI.DTOs.GraveSite;
using MerhumAPI.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace MerhumAPI.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class GraveSiteController : ControllerBase
{
    private readonly IGraveSiteService _graveSiteService;
    private readonly IConfiguration _configuration;

    public GraveSiteController(IGraveSiteService graveSiteService, IConfiguration configuration)
    {
        _graveSiteService = graveSiteService;
        _configuration = configuration;
    }

    [HttpGet]
    public async Task<ActionResult<PagedResponse<GraveSiteResponse>>> GetAll(
        [FromQuery] int? cemeteryId,
        [FromQuery] string? status,
        [FromQuery] int pageNumber = 1,
        [FromQuery] int pageSize = 20)
    {
        var result = await _graveSiteService.GetAllAsync(cemeteryId, status, pageNumber, pageSize);
        return Ok(result);
    }

    [HttpGet("{id:int}")]
    [AllowAnonymous]
    public async Task<ActionResult<ApiResponse<GraveSiteResponse>>> GetById(int id)
    {
        var site = await _graveSiteService.GetByIdAsync(id);
        if (site == null) return NotFound(ApiResponse<GraveSiteResponse>.Fail("Grave site not found."));
        return Ok(ApiResponse<GraveSiteResponse>.Ok(site));
    }

    [HttpPost]
    [Authorize(Policy = "DesktopAccess")]
    public async Task<ActionResult<ApiResponse<GraveSiteResponse>>> Create([FromBody] GraveSiteRequest request)
    {
        var site = await _graveSiteService.CreateAsync(request);
        return CreatedAtAction(nameof(GetById), new { id = site.Id }, ApiResponse<GraveSiteResponse>.Ok(site));
    }

    [HttpPut("{id:int}")]
    [Authorize(Policy = "DesktopAccess")]
    public async Task<IActionResult> Update(int id, [FromBody] GraveSiteRequest request)
    {
        var updated = await _graveSiteService.UpdateAsync(id, request);
        if (!updated) return NotFound(ApiResponse<object>.Fail("Grave site not found."));
        return NoContent();
    }

    [HttpPatch("{id:int}/assign")]
    [Authorize(Policy = "DesktopAccess")]
    public async Task<IActionResult> AssignDeceased(int id, [FromBody] AssignDeceasedRequest request)
    {
        var baseUrl = _configuration["AppSettings:BaseUrl"] ?? $"{Request.Scheme}://{Request.Host}";
        var updated = await _graveSiteService.AssignDeceasedAsync(id, request.DeceasedId, baseUrl);
        if (!updated) return NotFound(ApiResponse<object>.Fail("Grave site not found."));
        return NoContent();
    }

    [HttpDelete("{id:int}")]
    [Authorize(Policy = "AdminOnly")]
    public async Task<IActionResult> Delete(int id)
    {
        var deleted = await _graveSiteService.DeleteAsync(id);
        if (!deleted) return NotFound(ApiResponse<object>.Fail("Grave site not found."));
        return NoContent();
    }
}

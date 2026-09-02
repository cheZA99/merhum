using MerhumAPI.Common;
using MerhumAPI.DTOs.Deceased;
using MerhumAPI.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace MerhumAPI.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class DeceasedController : ControllerBase
{
    private readonly IDeceasedService _deceasedService;

    public DeceasedController(IDeceasedService deceasedService) => _deceasedService = deceasedService;

    [HttpGet]
    [Authorize(Policy = "DesktopAccess")]
    public async Task<ActionResult<PagedResponse<DeceasedResponse>>> GetAll(
        [FromQuery] string? search,
        [FromQuery] int? statusId,
        [FromQuery] int? cityId,
        [FromQuery] bool withoutGraveSite = false,
        [FromQuery] int pageNumber = 1,
        [FromQuery] int pageSize = 20)
    {
        var result = await _deceasedService.GetAllAsync(search, statusId, cityId, withoutGraveSite, pageNumber, pageSize);
        return Ok(result);
    }

    [HttpGet("my")]
    [Authorize(Policy = "MobileAccess")]
    public async Task<ActionResult<PagedResponse<DeceasedResponse>>> GetMy(
        [FromQuery] int pageNumber = 1,
        [FromQuery] int pageSize = 20)
    {
        var result = await _deceasedService.GetMyAsync(User.GetUserId(), pageNumber, pageSize);
        return Ok(result);
    }

    [HttpGet("{id:int}")]
    [Authorize(Policy = "MobileAccess")]
    public async Task<ActionResult<DeceasedResponse>> GetById(int id)
    {
        var deceased = await _deceasedService.GetByIdAsync(id, User.IsAdministrator() ? null : User.GetUserId());
        if (deceased == null) return NotFound();
        return Ok(deceased);
    }

    [HttpPost]
    [Authorize(Policy = "MobileAccess")]
    public async Task<ActionResult<DeceasedResponse>> Create([FromBody] DeceasedRequest request)
    {
        var deceased = await _deceasedService.CreateAsync(request, User.GetUserId());
        return CreatedAtAction(nameof(GetById), new { id = deceased.Id }, deceased);
    }

    [HttpPut("{id:int}")]
    [Authorize(Policy = "DesktopAccess")]
    public async Task<IActionResult> Update(int id, [FromBody] DeceasedRequest request)
    {
        var updated = await _deceasedService.UpdateAsync(id, request);
        if (!updated) return NotFound();
        return NoContent();
    }

    [HttpPatch("{id:int}/status")]
    [Authorize(Policy = "DesktopAccess")]
    public async Task<IActionResult> UpdateStatus(int id, [FromBody] UpdateStatusRequest request)
    {
        var result = await _deceasedService.UpdateStatusAsync(id, request.StatusId, request.Note, User.GetUserId());
        return result switch
        {
            StatusChangeResult.NotFound => NotFound(ApiResponse<object>.Fail("Deceased not found.")),
            StatusChangeResult.NotAllowed => BadRequest(ApiResponse<object>.Fail("Faza se mijenja redom i uz obaveznu napomenu.")),
            _ => NoContent()
        };
    }

    [HttpPost("{id:int}/photo")]
    [Authorize(Policy = "DesktopAccess")]
    public async Task<IActionResult> UploadPhoto(int id, IFormFile file)
    {
        if (file == null || file.Length == 0)
            return BadRequest(new { message = "No file provided." });

        var ext = Path.GetExtension(file.FileName).ToLowerInvariant();
        if (ext is not (".jpg" or ".jpeg" or ".png" or ".webp"))
            return BadRequest(new { message = "Unsupported file type." });

        var photoUrl = await _deceasedService.UploadPhotoAsync(id, file);
        if (photoUrl == null) return NotFound();

        return Ok(new { photoUrl });
    }

    [HttpDelete("{id:int}")]
    [Authorize(Policy = "AdminOnly")]
    public async Task<IActionResult> Delete(int id)
    {
        var deleted = await _deceasedService.DeleteAsync(id);
        if (!deleted) return NotFound();
        return NoContent();
    }

    [HttpGet("{id:int}/status-history")]
    [Authorize(Policy = "MobileAccess")]
    public async Task<IActionResult> GetStatusHistory(int id)
    {
        var history = await _deceasedService.GetStatusHistoryAsync(id, User.IsAdministrator() ? null : User.GetUserId());
        if (history == null) return NotFound();
        return Ok(history);
    }
}

public class UpdateStatusRequest
{
    public int StatusId { get; set; }
    public string? Note { get; set; }
}

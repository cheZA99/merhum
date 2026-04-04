using MerhumAPI.Common;
using MerhumAPI.DTOs.Condolence;
using MerhumAPI.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace MerhumAPI.Controllers;

[ApiController]
[Route("api/[controller]")]
public class CondolenceController : ControllerBase
{
    private readonly ICondolenceService _condolenceService;

    public CondolenceController(ICondolenceService condolenceService) => _condolenceService = condolenceService;

    [HttpGet]
    [Authorize(Policy = "DesktopAccess")]
    public async Task<ActionResult<PagedResponse<CondolenceResponse>>> GetAll(
        [FromQuery] int? obituaryId,
        [FromQuery] bool? isApproved,
        [FromQuery] int pageNumber = 1,
        [FromQuery] int pageSize = 20)
    {
        var result = await _condolenceService.GetAllAsync(obituaryId, isApproved, pageNumber, pageSize);
        return Ok(result);
    }

    [HttpGet("{id:int}")]
    [Authorize(Policy = "DesktopAccess")]
    public async Task<ActionResult<ApiResponse<CondolenceResponse>>> GetById(int id)
    {
        var condolence = await _condolenceService.GetByIdAsync(id);
        if (condolence == null) return NotFound(ApiResponse<CondolenceResponse>.Fail("Condolence not found."));
        return Ok(ApiResponse<CondolenceResponse>.Ok(condolence));
    }

    [HttpPost]
    [AllowAnonymous]
    public async Task<ActionResult<ApiResponse<CondolenceResponse>>> Submit([FromBody] CondolenceRequest request)
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier)
                  ?? User.FindFirstValue("sub");

        var condolence = await _condolenceService.CreateAsync(request, userId);
        return Ok(ApiResponse<CondolenceResponse>.Ok(condolence, "Condolence submitted and awaiting approval."));
    }

    [HttpPatch("{id:int}/approve")]
    [Authorize(Policy = "DesktopAccess")]
    public async Task<IActionResult> Approve(int id)
    {
        var approved = await _condolenceService.ApproveAsync(id);
        if (!approved) return NotFound(ApiResponse<object>.Fail("Condolence not found."));
        return NoContent();
    }

    [HttpDelete("{id:int}")]
    [Authorize(Policy = "AdminOnly")]
    public async Task<IActionResult> Delete(int id)
    {
        var deleted = await _condolenceService.DeleteAsync(id);
        if (!deleted) return NotFound(ApiResponse<object>.Fail("Condolence not found."));
        return NoContent();
    }
}

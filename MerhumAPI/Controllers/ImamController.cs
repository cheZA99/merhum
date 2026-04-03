using MerhumAPI.Common;
using MerhumAPI.DTOs.Imam;
using MerhumAPI.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace MerhumAPI.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class ImamController : ControllerBase
{
    private readonly IImamService _imamService;

    public ImamController(IImamService imamService) => _imamService = imamService;

    [HttpGet]
    public async Task<ActionResult<PagedResponse<ImamResponse>>> GetAll(
        [FromQuery] int? mosqueId,
        [FromQuery] bool? isActive,
        [FromQuery] int pageNumber = 1,
        [FromQuery] int pageSize = 20)
    {
        var result = await _imamService.GetAllAsync(mosqueId, isActive, pageNumber, pageSize);
        return Ok(result);
    }

    [HttpGet("{id:int}")]
    public async Task<ActionResult<ApiResponse<ImamResponse>>> GetById(int id)
    {
        var imam = await _imamService.GetByIdAsync(id);
        if (imam == null) return NotFound(ApiResponse<ImamResponse>.Fail("Imam not found."));
        return Ok(ApiResponse<ImamResponse>.Ok(imam));
    }

    [HttpPost]
    [Authorize(Policy = "AdminOnly")]
    public async Task<ActionResult<ApiResponse<ImamResponse>>> Create([FromBody] ImamRequest request)
    {
        var imam = await _imamService.CreateAsync(request);
        return CreatedAtAction(nameof(GetById), new { id = imam.Id }, ApiResponse<ImamResponse>.Ok(imam));
    }

    [HttpPut("{id:int}")]
    [Authorize(Policy = "AdminOnly")]
    public async Task<IActionResult> Update(int id, [FromBody] ImamRequest request)
    {
        var updated = await _imamService.UpdateAsync(id, request);
        if (!updated) return NotFound(ApiResponse<object>.Fail("Imam not found."));
        return NoContent();
    }

    [HttpDelete("{id:int}")]
    [Authorize(Policy = "AdminOnly")]
    public async Task<IActionResult> Delete(int id)
    {
        var deleted = await _imamService.DeleteAsync(id);
        if (!deleted) return NotFound(ApiResponse<object>.Fail("Imam not found."));
        return NoContent();
    }
}

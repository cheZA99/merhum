using MerhumAPI.Common;
using MerhumAPI.DTOs.FuneralHome;
using MerhumAPI.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace MerhumAPI.Controllers;

[ApiController]
[Route("api/[controller]")]
public class FuneralHomeController : ControllerBase
{
    private readonly IFuneralHomeService _funeralHomeService;

    public FuneralHomeController(IFuneralHomeService funeralHomeService) => _funeralHomeService = funeralHomeService;

    [HttpGet]
    [AllowAnonymous]
    public async Task<ActionResult<PagedResponse<FuneralHomeResponse>>> GetAll(
        [FromQuery] string? search,
        [FromQuery] int pageNumber = 1,
        [FromQuery] int pageSize = 20)
    {
        var result = await _funeralHomeService.GetAllAsync(search, pageNumber, pageSize);
        return Ok(result);
    }

    [HttpGet("{id:int}")]
    [AllowAnonymous]
    public async Task<ActionResult<ApiResponse<FuneralHomeResponse>>> GetById(int id)
    {
        var home = await _funeralHomeService.GetByIdAsync(id);
        if (home == null) return NotFound(ApiResponse<FuneralHomeResponse>.Fail("Funeral home not found."));
        return Ok(ApiResponse<FuneralHomeResponse>.Ok(home));
    }

    [HttpPost]
    [Authorize(Policy = "AdminOnly")]
    public async Task<ActionResult<ApiResponse<FuneralHomeResponse>>> Create([FromBody] FuneralHomeRequest request)
    {
        var home = await _funeralHomeService.CreateAsync(request);
        return CreatedAtAction(nameof(GetById), new { id = home.Id }, ApiResponse<FuneralHomeResponse>.Ok(home));
    }

    [HttpPut("{id:int}")]
    [Authorize(Policy = "AdminOnly")]
    public async Task<IActionResult> Update(int id, [FromBody] FuneralHomeRequest request)
    {
        var updated = await _funeralHomeService.UpdateAsync(id, request);
        if (!updated) return NotFound(ApiResponse<object>.Fail("Funeral home not found."));
        return NoContent();
    }

    [HttpDelete("{id:int}")]
    [Authorize(Policy = "AdminOnly")]
    public async Task<IActionResult> Delete(int id)
    {
        var deleted = await _funeralHomeService.DeleteAsync(id);
        if (!deleted) return NotFound(ApiResponse<object>.Fail("Funeral home not found."));
        return NoContent();
    }
}

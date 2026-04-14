using MerhumAPI.Common;
using MerhumAPI.DTOs.User;
using MerhumAPI.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace MerhumAPI.Controllers;

[ApiController]
[Route("api/korisnici")]
[Authorize(Policy = "AdminOnly")]
public class UserController : ControllerBase
{
    private readonly IUserService _userService;

    public UserController(IUserService userService) => _userService = userService;

    [HttpGet]
    public async Task<ActionResult<PagedResponse<UserResponse>>> GetAll(
        [FromQuery] string? name,
        [FromQuery] string? username,
        [FromQuery] string? role,
        [FromQuery] bool? isLocked,
        [FromQuery] int pageNumber = 1,
        [FromQuery] int pageSize = 10)
    {
        var result = await _userService.GetAllAsync(name, username, role, isLocked, pageNumber, pageSize);
        return Ok(result);
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<ApiResponse<UserResponse>>> GetById(string id)
    {
        var user = await _userService.GetByIdAsync(id);
        if (user == null) return NotFound(ApiResponse<UserResponse>.Fail("Korisnik nije pronađen."));
        return Ok(ApiResponse<UserResponse>.Ok(user));
    }

    [HttpPut("{id}")]
    public async Task<IActionResult> Update(string id, [FromBody] UserUpdateRequest request)
    {
        var updated = await _userService.UpdateAsync(id, request);
        if (!updated) return NotFound(ApiResponse<object>.Fail("Korisnik nije pronađen ili je uloga neispravna."));
        return NoContent();
    }

    [HttpPut("{id}/lock")]
    public async Task<IActionResult> ToggleLock(string id)
    {
        var toggled = await _userService.ToggleLockAsync(id);
        if (!toggled) return NotFound(ApiResponse<object>.Fail("Korisnik nije pronađen."));
        return NoContent();
    }

    [HttpPut("{id}/role")]
    public async Task<IActionResult> ChangeRole(string id, [FromBody] ChangeRoleRequest request)
    {
        var changed = await _userService.ChangeRoleAsync(id, request.Role);
        if (!changed) return NotFound(ApiResponse<object>.Fail("Korisnik nije pronađen."));
        return NoContent();
    }

    [HttpPut("{id}/reset-password")]
    public async Task<IActionResult> ResetPassword(string id)
    {
        var reset = await _userService.ResetPasswordAsync(id);
        if (!reset) return NotFound(ApiResponse<object>.Fail("Korisnik nije pronađen."));
        return NoContent();
    }
}

public class ChangeRoleRequest
{
    public string Role { get; set; } = string.Empty;
}

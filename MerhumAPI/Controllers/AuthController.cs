using MerhumAPI.Common;
using MerhumAPI.DTOs.Auth;
using MerhumAPI.Models;
using MerhumAPI.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;

namespace MerhumAPI.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private readonly UserManager<ApplicationUser> _userManager;
    private readonly SignInManager<ApplicationUser> _signInManager;
    private readonly ITokenService _tokenService;
    private readonly IConfiguration _configuration;

    public AuthController(
        UserManager<ApplicationUser> userManager,
        SignInManager<ApplicationUser> signInManager,
        ITokenService tokenService,
        IConfiguration configuration)
    {
        _userManager = userManager;
        _signInManager = signInManager;
        _tokenService = tokenService;
        _configuration = configuration;
    }

    [HttpPost("login")]
    public async Task<ActionResult<LoginResponse>> Login([FromBody] LoginRequest request)
    {
        var user = await _userManager.FindByNameAsync(request.Username);
        if (user == null || !user.IsActive)
            return Unauthorized(new { message = "Invalid credentials." });

        var result = await _signInManager.CheckPasswordSignInAsync(user, request.Password, false);
        if (!result.Succeeded)
            return Unauthorized(new { message = "Invalid credentials." });

        var roles = await _userManager.GetRolesAsync(user);
        var token = await _tokenService.GenerateTokenAsync(user);
        var expiresInMinutes = double.Parse(_configuration["JWT:ExpiresInMinutes"] ?? "60");

        return Ok(new LoginResponse
        {
            Token = token,
            Username = user.UserName ?? string.Empty,
            FirstName = user.FirstName,
            LastName = user.LastName,
            FullName = user.FullName,
            Role = roles.FirstOrDefault() ?? string.Empty,
            Roles = roles,
            ExpiresAt = DateTime.UtcNow.AddMinutes(expiresInMinutes)
        });
    }

    [HttpPost("register")]
    [AllowAnonymous]
    public async Task<ActionResult<ApiResponse<object>>> Register([FromBody] RegisterRequest request)
    {
        var existing = await _userManager.FindByNameAsync(request.Username);
        if (existing != null)
            return Conflict(ApiResponse<object>.Fail("Korisničko ime je zauzeto."));

        var emailExisting = await _userManager.FindByEmailAsync(request.Email);
        if (emailExisting != null)
            return Conflict(ApiResponse<object>.Fail("Email adresa je zauzeta."));

        var user = new ApplicationUser
        {
            UserName = request.Username,
            Email = request.Email,
            FirstName = request.FirstName,
            LastName = request.LastName,
            PhoneNumber = request.Phone,
            EmailConfirmed = true,
            IsActive = true
        };

        var result = await _userManager.CreateAsync(user, request.Password);
        if (!result.Succeeded)
        {
            var errors = string.Join(", ", result.Errors.Select(e => e.Description));
            return BadRequest(ApiResponse<object>.Fail(errors));
        }

        // public registration is family-only; other roles via register-admin
        await _userManager.AddToRoleAsync(user, "Porodica");

        return Ok(ApiResponse<object>.Ok(new { user.Id }, "Registracija uspješna."));
    }

    [HttpPost("register-admin")]
    [Authorize(Policy = "AdminOnly")]
    public async Task<ActionResult<ApiResponse<object>>> RegisterAdmin([FromBody] AdminRegisterRequest request)
    {
        var existing = await _userManager.FindByNameAsync(request.Username);
        if (existing != null)
            return Conflict(ApiResponse<object>.Fail("Korisničko ime je zauzeto."));

        var emailExisting = await _userManager.FindByEmailAsync(request.Email);
        if (emailExisting != null)
            return Conflict(ApiResponse<object>.Fail("Email adresa je zauzeta."));

        var validRoles = new[] { "Administrator", "Porodica", "JavniKorisnik", "Imam", "PogrebnoPreduzeće" };
        if (!validRoles.Contains(request.Role))
            return BadRequest(ApiResponse<object>.Fail("Neispravna uloga."));

        var user = new ApplicationUser
        {
            UserName = request.Username,
            Email = request.Email,
            FirstName = request.FirstName,
            LastName = request.LastName,
            PhoneNumber = request.Phone,
            CityId = request.CityId,
            EmailConfirmed = true,
            IsActive = true
        };

        var result = await _userManager.CreateAsync(user, request.Password);
        if (!result.Succeeded)
        {
            var errors = string.Join(", ", result.Errors.Select(e => e.Description));
            return BadRequest(ApiResponse<object>.Fail(errors));
        }

        await _userManager.AddToRoleAsync(user, request.Role);

        return Ok(ApiResponse<object>.Ok(new { user.Id }, "Korisnik uspješno kreiran."));
    }

    [HttpPost("change-password")]
    [Microsoft.AspNetCore.Authorization.Authorize]
    public async Task<ActionResult<ApiResponse<object>>> ChangePassword([FromBody] ChangePasswordRequest request)
    {
        var userId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value
                  ?? User.FindFirst("sub")?.Value;
        if (userId == null) return Unauthorized();

        var user = await _userManager.FindByIdAsync(userId);
        if (user == null) return NotFound(ApiResponse<object>.Fail("Korisnik nije pronađen."));

        var result = await _userManager.ChangePasswordAsync(user, request.CurrentPassword, request.NewPassword);
        if (!result.Succeeded)
        {
            var wrongPassword = result.Errors.Any(e => e.Code == "PasswordMismatch");
            var message = wrongPassword
                ? "Stara lozinka nije ispravna."
                : string.Join(", ", result.Errors.Select(e => e.Description));
            return BadRequest(ApiResponse<object>.Fail(message));
        }

        return Ok(ApiResponse<object>.Ok(new { }, "Lozinka je uspješno promijenjena."));
    }

    [HttpGet("me")]
    [Microsoft.AspNetCore.Authorization.Authorize]
    public async Task<IActionResult> Me()
    {
        var userId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value
                  ?? User.FindFirst("sub")?.Value;

        if (userId == null) return Unauthorized();

        var user = await _userManager.FindByIdAsync(userId);
        if (user == null) return NotFound();

        var roles = await _userManager.GetRolesAsync(user);

        return Ok(new
        {
            user.Id,
            user.UserName,
            user.Email,
            user.FullName,
            Roles = roles
        });
    }
}

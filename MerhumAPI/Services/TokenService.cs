using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using MerhumAPI.Models;
using Microsoft.AspNetCore.Identity;
using Microsoft.IdentityModel.Tokens;

namespace MerhumAPI.Services;

public class TokenService : ITokenService
{
    private readonly IConfiguration _configuration;
    private readonly UserManager<ApplicationUser> _userManager;

    public TokenService(IConfiguration configuration, UserManager<ApplicationUser> userManager)
    {
        _configuration = configuration;
        _userManager = userManager;
    }

    public async Task<string> GenerateTokenAsync(ApplicationUser user)
    {
        var roles = await _userManager.GetRolesAsync(user);

        var claims = new List<Claim>
        {
            new Claim(JwtRegisteredClaimNames.Sub, user.Id),
            new Claim(JwtRegisteredClaimNames.UniqueName, user.UserName ?? string.Empty),
            new Claim(JwtRegisteredClaimNames.Email, user.Email ?? string.Empty),
            new Claim("fullName", user.FullName),
            new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString())
        };

        claims.AddRange(roles.Select(role => new Claim(ClaimTypes.Role, role)));

        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(
            _configuration["JWT:Key"] ?? throw new InvalidOperationException("JWT:Key is not configured")));

        var credentials = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);
        var expires = DateTime.UtcNow.AddMinutes(double.Parse(_configuration["JWT:ExpiresInMinutes"] ?? "60"));

        var token = new JwtSecurityToken(
            issuer: _configuration["JWT:Issuer"],
            audience: _configuration["JWT:Audience"],
            claims: claims,
            expires: expires,
            signingCredentials: credentials
        );

        return new JwtSecurityTokenHandler().WriteToken(token);
    }
}

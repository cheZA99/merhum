using MerhumAPI.Models;

namespace MerhumAPI.Services;

public interface ITokenService
{
    Task<string> GenerateTokenAsync(ApplicationUser user);
}

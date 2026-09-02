using System.Security.Claims;

namespace MerhumAPI.Common;

public static class UserClaims
{
    public static string GetUserId(this ClaimsPrincipal user) =>
        user.FindFirstValue(ClaimTypes.NameIdentifier)
        ?? user.FindFirstValue("sub")
        ?? throw new UnauthorizedAccessException();

    public static bool IsAdministrator(this ClaimsPrincipal user) => user.IsInRole("Administrator");
}

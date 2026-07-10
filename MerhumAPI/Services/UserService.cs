using MerhumAPI.Common;
using MerhumAPI.DTOs.User;
using MerhumAPI.Models;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;

namespace MerhumAPI.Services;

public class UserService : IUserService
{
    private readonly UserManager<ApplicationUser> _userManager;

    public UserService(UserManager<ApplicationUser> userManager) => _userManager = userManager;

    public async Task<PagedResponse<UserResponse>> GetAllAsync(
        string? name, string? username, string? role, bool? isLocked,
        int pageNumber, int pageSize)
    {
        (pageNumber, pageSize) = Pagination.Normalize(pageNumber, pageSize);

        var query = _userManager.Users
            .Include(u => u.City)
            .AsQueryable();

        if (!string.IsNullOrWhiteSpace(name))
            query = query.Where(u =>
                u.FirstName.Contains(name) ||
                u.LastName.Contains(name) ||
                (u.UserName != null && u.UserName.Contains(name)));

        if (!string.IsNullOrWhiteSpace(username))
            query = query.Where(u => u.UserName != null && u.UserName.Contains(username));

        if (isLocked.HasValue)
            query = isLocked.Value
                ? query.Where(u => !u.IsActive)
                : query.Where(u => u.IsActive);

        var allUsers = await query.OrderBy(u => u.UserName).ToListAsync();

        // role filter runs in memory (async role lookup)
        List<ApplicationUser> filtered;
        if (!string.IsNullOrWhiteSpace(role))
        {
            var usersInRole = await _userManager.GetUsersInRoleAsync(role);
            var usersInRoleIds = usersInRole.Select(u => u.Id).ToHashSet();
            filtered = allUsers.Where(u => usersInRoleIds.Contains(u.Id)).ToList();
        }
        else
        {
            filtered = allUsers;
        }

        var total = filtered.Count;
        var paged = filtered
            .Skip((pageNumber - 1) * pageSize)
            .Take(pageSize)
            .ToList();

        var responses = new List<UserResponse>();
        foreach (var u in paged)
        {
            var roles = await _userManager.GetRolesAsync(u);
            responses.Add(MapToResponse(u, roles.FirstOrDefault() ?? string.Empty));
        }

        return PagedResponse<UserResponse>.Create(responses, total, pageNumber, pageSize);
    }

    public async Task<UserResponse?> GetByIdAsync(string id)
    {
        var user = await _userManager.Users
            .Include(u => u.City)
            .FirstOrDefaultAsync(u => u.Id == id);

        if (user == null) return null;

        var roles = await _userManager.GetRolesAsync(user);
        return MapToResponse(user, roles.FirstOrDefault() ?? string.Empty);
    }

    public async Task<bool> UpdateAsync(string id, UserUpdateRequest request)
    {
        var user = await _userManager.FindByIdAsync(id);
        if (user == null) return false;

        var validRoles = new[] { "Administrator", "Porodica", "JavniKorisnik", "Imam", "PogrebnoPreduzeće" };
        if (!validRoles.Contains(request.Role))
            return false;

        user.FirstName = request.FirstName;
        user.LastName = request.LastName;
        user.Email = request.Email;
        user.NormalizedEmail = request.Email.ToUpperInvariant();
        user.PhoneNumber = request.Phone;
        user.CityId = request.CityId;

        var updateResult = await _userManager.UpdateAsync(user);
        if (!updateResult.Succeeded) return false;

        var currentRoles = await _userManager.GetRolesAsync(user);
        var currentRole = currentRoles.FirstOrDefault();
        if (currentRole != request.Role)
        {
            if (currentRole != null)
                await _userManager.RemoveFromRoleAsync(user, currentRole);
            await _userManager.AddToRoleAsync(user, request.Role);
        }

        if (!string.IsNullOrWhiteSpace(request.NewPassword))
        {
            var token = await _userManager.GeneratePasswordResetTokenAsync(user);
            await _userManager.ResetPasswordAsync(user, token, request.NewPassword);
        }

        return true;
    }

    public async Task<bool> ToggleLockAsync(string id)
    {
        var user = await _userManager.FindByIdAsync(id);
        if (user == null) return false;

        user.IsActive = !user.IsActive;
        var result = await _userManager.UpdateAsync(user);
        return result.Succeeded;
    }

    public async Task<bool> ChangeRoleAsync(string id, string role)
    {
        var user = await _userManager.FindByIdAsync(id);
        if (user == null) return false;

        var currentRoles = await _userManager.GetRolesAsync(user);
        await _userManager.RemoveFromRolesAsync(user, currentRoles);
        var result = await _userManager.AddToRoleAsync(user, role);
        return result.Succeeded;
    }

    public async Task<bool> ResetPasswordAsync(string id)
    {
        var user = await _userManager.FindByIdAsync(id);
        if (user == null) return false;

        var token = await _userManager.GeneratePasswordResetTokenAsync(user);
        var result = await _userManager.ResetPasswordAsync(user, token, "test");
        return result.Succeeded;
    }

    private static UserResponse MapToResponse(ApplicationUser u, string role) => new()
    {
        Id = u.Id,
        Username = u.UserName ?? string.Empty,
        FirstName = u.FirstName,
        LastName = u.LastName,
        FullName = u.FullName,
        Email = u.Email ?? string.Empty,
        Phone = u.PhoneNumber,
        Role = role,
        CityName = u.City?.Name,
        IsConfirmed = u.EmailConfirmed,
        IsLocked = !u.IsActive,
        RegisteredAt = u.CreatedAt,
    };
}

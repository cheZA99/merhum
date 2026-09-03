using MerhumAPI.Common;
using MerhumAPI.Data;
using MerhumAPI.DTOs.User;
using MerhumAPI.Models;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;

namespace MerhumAPI.Services;

public class UserService : IUserService
{
    private readonly UserManager<ApplicationUser> _userManager;
    private readonly ApplicationDbContext _db;

    public UserService(UserManager<ApplicationUser> userManager, ApplicationDbContext db)
    {
        _userManager = userManager;
        _db = db;
    }

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

        if (!string.IsNullOrWhiteSpace(role))
        {
            var roleId = await _db.Roles.Where(r => r.Name == role).Select(r => r.Id).FirstOrDefaultAsync();
            query = query.Where(u => _db.UserRoles.Any(ur => ur.UserId == u.Id && ur.RoleId == roleId));
        }

        var total = await query.CountAsync();
        var paged = await query
            .OrderBy(u => u.UserName)
            .Skip((pageNumber - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        // one lookup for the whole page instead of one per user
        var pagedIds = paged.Select(u => u.Id).ToList();
        var pagedRoles = await (from ur in _db.UserRoles
                                join r in _db.Roles on ur.RoleId equals r.Id
                                where pagedIds.Contains(ur.UserId)
                                select new { ur.UserId, RoleName = r.Name })
            .ToListAsync();

        var roleByUser = pagedRoles.ToLookup(x => x.UserId, x => x.RoleName ?? string.Empty);

        var responses = paged
            .Select(u => MapToResponse(u, roleByUser[u.Id].FirstOrDefault() ?? string.Empty))
            .ToList();

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

        if (!Roles.All.Contains(request.Role))
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
            {
                var removeResult = await _userManager.RemoveFromRoleAsync(user, currentRole);
                if (!removeResult.Succeeded) return false;
            }

            var addResult = await _userManager.AddToRoleAsync(user, request.Role);
            if (!addResult.Succeeded) return false;
        }

        if (!string.IsNullOrWhiteSpace(request.NewPassword))
        {
            var token = await _userManager.GeneratePasswordResetTokenAsync(user);
            var passwordResult = await _userManager.ResetPasswordAsync(user, token, request.NewPassword);
            if (!passwordResult.Succeeded) return false;
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

        // the new role is checked first, so a bad name cannot leave the user with none
        if (!Roles.All.Contains(role)) return false;

        var currentRoles = await _userManager.GetRolesAsync(user);
        if (currentRoles.Count > 0)
        {
            var removeResult = await _userManager.RemoveFromRolesAsync(user, currentRoles);
            if (!removeResult.Succeeded) return false;
        }

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

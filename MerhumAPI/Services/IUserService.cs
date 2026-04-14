using MerhumAPI.Common;
using MerhumAPI.DTOs.User;

namespace MerhumAPI.Services;

public interface IUserService
{
    Task<PagedResponse<UserResponse>> GetAllAsync(string? name, string? username, string? role, bool? isLocked, int pageNumber, int pageSize);
    Task<UserResponse?> GetByIdAsync(string id);
    Task<bool> UpdateAsync(string id, UserUpdateRequest request);
    Task<bool> ToggleLockAsync(string id);
    Task<bool> ChangeRoleAsync(string id, string role);
    Task<bool> ResetPasswordAsync(string id);
}

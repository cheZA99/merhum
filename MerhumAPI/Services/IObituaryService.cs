using MerhumAPI.Common;
using MerhumAPI.DTOs.Obituary;

namespace MerhumAPI.Services;

public interface IObituaryService
{
    Task<PagedResponse<ObituaryResponse>> GetAllAsync(bool? isPublic, bool? isActive, string? deceasedName, int pageNumber, int pageSize);
    Task<ObituaryResponse?> GetByIdAsync(int id);
    Task<ObituaryResponse?> GetBySlugAsync(string slug);
    Task<ObituaryResponse> CreateAsync(int deceasedId, bool isPublic, string userId);
    Task<bool> UpdateAsync(int id, bool isPublic, bool isActive);
    Task<bool> DeleteAsync(int id);
    Task IncrementViewCountAsync(int obituaryId);
}

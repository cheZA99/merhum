using MerhumAPI.Common;
using MerhumAPI.DTOs.GraveSite;

namespace MerhumAPI.Services;

public interface IGraveSiteService
{
    Task<PagedResponse<GraveSiteResponse>> GetAllAsync(int? cemeteryId, string? status, int pageNumber, int pageSize);
    Task<GraveSiteResponse?> GetByIdAsync(int id);
    Task<GraveSiteResponse> CreateAsync(GraveSiteRequest request);
    Task<bool> UpdateAsync(int id, GraveSiteRequest request);
    Task<bool> AssignDeceasedAsync(int id, int deceasedId, string baseUrl);
    Task<bool> DeleteAsync(int id);
}

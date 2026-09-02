using MerhumAPI.Common;
using MerhumAPI.DTOs.GraveSite;
using MerhumAPI.Models;

namespace MerhumAPI.Services;

public interface IGraveSiteService
{
    Task<PagedResponse<GraveSiteResponse>> GetAllAsync(int? cemeteryId, GraveSiteStatus? status, int pageNumber, int pageSize);
    Task<GraveSiteResponse?> GetByIdAsync(int id);
    Task<GraveSiteResponse> CreateAsync(GraveSiteRequest request);
    Task<bool> UpdateAsync(int id, GraveSiteRequest request);
    Task<bool> AssignDeceasedAsync(int id, int deceasedId, string baseUrl);
    Task<bool> UnassignDeceasedAsync(int id);
    Task<bool> UpdateStatusAsync(int id, GraveSiteStatus status);
    Task<bool> DeleteAsync(int id);
}

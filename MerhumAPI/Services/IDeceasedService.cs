using MerhumAPI.Common;
using MerhumAPI.DTOs.Deceased;

namespace MerhumAPI.Services;

public interface IDeceasedService
{
    Task<PagedResponse<DeceasedResponse>> GetAllAsync(string? search, int? statusId, int? cityId, bool withoutGraveSite, int pageNumber, int pageSize);
    Task<PagedResponse<DeceasedResponse>> GetMyAsync(string userId, int pageNumber, int pageSize);
    Task<DeceasedResponse?> GetByIdAsync(int id);
    Task<DeceasedResponse> CreateAsync(DeceasedRequest request, string userId);
    Task<bool> UpdateAsync(int id, DeceasedRequest request);
    Task<bool> UpdateStatusAsync(int id, int statusId, string? note, string changedByUserId);
    Task<string?> UploadPhotoAsync(int id, IFormFile file);
    Task<bool> DeleteAsync(int id);
    Task<List<StatusHistoryResponse>> GetStatusHistoryAsync(int id);
}

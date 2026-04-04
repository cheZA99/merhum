using MerhumAPI.Common;
using MerhumAPI.DTOs.Condolence;

namespace MerhumAPI.Services;

public interface ICondolenceService
{
    Task<PagedResponse<CondolenceResponse>> GetAllAsync(int? obituaryId, bool? isApproved, int pageNumber, int pageSize);
    Task<CondolenceResponse?> GetByIdAsync(int id);
    Task<CondolenceResponse> CreateAsync(CondolenceRequest request, string? userId);
    Task<bool> ApproveAsync(int id);
    Task<bool> DeleteAsync(int id);
}

using MerhumAPI.Common;
using MerhumAPI.DTOs.Imam;

namespace MerhumAPI.Services;

public interface IImamService
{
    Task<PagedResponse<ImamResponse>> GetAllAsync(int? mosqueId, bool? isActive, int pageNumber, int pageSize);
    Task<ImamResponse?> GetByIdAsync(int id);
    Task<ImamResponse> CreateAsync(ImamRequest request);
    Task<bool> UpdateAsync(int id, ImamRequest request);
    Task<bool> DeleteAsync(int id);
}

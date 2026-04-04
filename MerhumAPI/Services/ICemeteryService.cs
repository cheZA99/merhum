using MerhumAPI.Common;
using MerhumAPI.DTOs.Cemetery;

namespace MerhumAPI.Services;

public interface ICemeteryService
{
    Task<PagedResponse<CemeteryResponse>> GetAllAsync(string? search, int pageNumber, int pageSize);
    Task<CemeteryResponse?> GetByIdAsync(int id);
    Task<CemeteryResponse> CreateAsync(CemeteryRequest request);
    Task<bool> UpdateAsync(int id, CemeteryRequest request);
    Task<bool> DeleteAsync(int id);
}

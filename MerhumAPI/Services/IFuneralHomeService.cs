using MerhumAPI.Common;
using MerhumAPI.DTOs.FuneralHome;

namespace MerhumAPI.Services;

public interface IFuneralHomeService
{
    Task<PagedResponse<FuneralHomeResponse>> GetAllAsync(string? search, int pageNumber, int pageSize);
    Task<FuneralHomeResponse?> GetByIdAsync(int id);
    Task<FuneralHomeResponse> CreateAsync(FuneralHomeRequest request);
    Task<bool> UpdateAsync(int id, FuneralHomeRequest request);
    Task<bool> DeleteAsync(int id);
}

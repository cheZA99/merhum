using MerhumAPI.Common;
using MerhumAPI.DTOs.Mosque;

namespace MerhumAPI.Services;

public interface IMosqueService
{
    Task<PagedResponse<MosqueResponse>> GetAllAsync(string? search, int pageNumber, int pageSize);
    Task<MosqueResponse?> GetByIdAsync(int id);
    Task<MosqueResponse> CreateAsync(MosqueRequest request);
    Task<bool> UpdateAsync(int id, MosqueRequest request);
    Task<bool> DeleteAsync(int id);
}

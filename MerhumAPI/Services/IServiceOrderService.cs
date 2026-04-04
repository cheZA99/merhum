using MerhumAPI.Common;
using MerhumAPI.DTOs.ServiceOrder;

namespace MerhumAPI.Services;

public interface IServiceOrderService
{
    Task<PagedResponse<ServiceOrderResponse>> GetAllAsync(int? deceasedId, string? status, int pageNumber, int pageSize);
    Task<ServiceOrderResponse?> GetByIdAsync(int id);
    Task<ServiceOrderResponse> CreateAsync(ServiceOrderRequest request);
    Task<bool> UpdateStatusAsync(int id, string status);
    Task<bool> DeleteAsync(int id);
}

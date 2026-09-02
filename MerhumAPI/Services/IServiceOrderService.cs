using MerhumAPI.Common;
using MerhumAPI.DTOs.ServiceOrder;
using MerhumAPI.Models;

namespace MerhumAPI.Services;

public interface IServiceOrderService
{
    Task<PagedResponse<ServiceOrderResponse>> GetAllAsync(int? deceasedId, ServiceOrderStatus? status, int? funeralHomeId, DateTime? dateFrom, DateTime? dateTo, int pageNumber, int pageSize);
    Task<ServiceOrderResponse?> GetByIdAsync(int id);
    Task<ServiceOrderResponse> CreateAsync(ServiceOrderRequest request);
    Task<ServiceOrderResponse?> UpdateAsync(int id, ServiceOrderUpdateRequest request);
    Task<bool> UpdateStatusAsync(int id, ServiceOrderStatus status, DateTime? completedAt);
    Task<bool> DeleteAsync(int id);
}

using MerhumAPI.Common;
using MerhumAPI.DTOs.ServiceOrder;
using MerhumAPI.Models;

namespace MerhumAPI.Services;

public interface IServiceOrderService
{
    Task<PagedResponse<ServiceOrderResponse>> GetAllAsync(int? deceasedId, ServiceOrderStatus? status, int? funeralHomeId, DateTime? dateFrom, DateTime? dateTo, int pageNumber, int pageSize, string? scopeToUserId);
    Task<ServiceOrderResponse?> GetByIdAsync(int id, string? scopeToUserId);
    Task<ServiceOrderResponse?> CreateAsync(ServiceOrderRequest request, string? scopeToUserId);
    Task<ServiceOrderResponse?> UpdateAsync(int id, ServiceOrderUpdateRequest request);
    Task<StatusChangeResult> UpdateStatusAsync(int id, ServiceOrderStatus status, string changedByUserId, string? reason, string? scopeToUserId);
}

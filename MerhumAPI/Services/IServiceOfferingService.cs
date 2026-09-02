using MerhumAPI.Common;
using MerhumAPI.DTOs.ServiceOffering;

namespace MerhumAPI.Services;

public interface IServiceOfferingService
{
    Task<PagedResponse<ServiceOfferingResponse>> GetAllAsync(int? funeralHomeId, bool activeOnly, int pageNumber, int pageSize);
    Task<ServiceOfferingResponse?> GetByIdAsync(int id);
    Task<ServiceOfferingResponse> CreateAsync(ServiceOfferingRequest request);
    Task<ServiceOfferingResponse?> UpdateAsync(int id, ServiceOfferingRequest request);
    Task<bool> DeleteAsync(int id);
}

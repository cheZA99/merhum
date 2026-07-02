using MerhumAPI.Common;
using MerhumAPI.DTOs.Appointment;

namespace MerhumAPI.Services;

public interface IAppointmentService
{
    Task<PagedResponse<AppointmentResponse>> GetAllAsync(int? deceasedId, string? status, int? mosqueId, int? imamId, int? cityId, DateTime? dateFrom, DateTime? dateTo, int pageNumber, int pageSize);
    Task<AppointmentResponse?> GetByIdAsync(int id);
    Task<AppointmentResponse> CreateAsync(AppointmentRequest request, string userId);
    Task<AppointmentResponse?> UpdateAsync(int id, AppointmentRequest request);
    Task<bool> UpdateStatusAsync(int id, string status);
    Task<bool> DeleteAsync(int id);
}

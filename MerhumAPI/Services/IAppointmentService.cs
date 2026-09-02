using MerhumAPI.Common;
using MerhumAPI.DTOs.Appointment;
using MerhumAPI.Models;

namespace MerhumAPI.Services;

public interface IAppointmentService
{
    Task<PagedResponse<AppointmentResponse>> GetAllAsync(int? deceasedId, AppointmentStatus? status, int? mosqueId, int? imamId, int? cityId, DateTime? dateFrom, DateTime? dateTo, int pageNumber, int pageSize, string? scopeToUserId);
    Task<AppointmentResponse?> GetByIdAsync(int id, string? scopeToUserId);
    Task<AppointmentResponse> CreateAsync(AppointmentRequest request, string userId);
    Task<AppointmentResponse?> UpdateAsync(int id, AppointmentRequest request);
    Task<StatusChangeResult> UpdateStatusAsync(int id, AppointmentStatus status, string changedByUserId, string? reason);
}

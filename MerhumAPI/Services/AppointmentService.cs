using MassTransit;
using MerhumAPI.Common;
using MerhumAPI.Data;
using MerhumAPI.DTOs.Appointment;
using MerhumAPI.Messages;
using MerhumAPI.Models;
using Microsoft.EntityFrameworkCore;

namespace MerhumAPI.Services;

public class AppointmentService : IAppointmentService
{
    private readonly ApplicationDbContext _db;
    private readonly IPublishEndpoint _publishEndpoint;

    public AppointmentService(ApplicationDbContext db, IPublishEndpoint publishEndpoint)
    {
        _db = db;
        _publishEndpoint = publishEndpoint;
    }

    public async Task<PagedResponse<AppointmentResponse>> GetAllAsync(int? deceasedId, string? status, int pageNumber, int pageSize)
    {
        var query = _db.Appointments
            .Include(a => a.Deceased)
            .Include(a => a.Mosque)
            .Include(a => a.Cemetery)
            .Include(a => a.Imam)
            .Include(a => a.GraveSite)
            .AsQueryable();

        if (deceasedId.HasValue)
            query = query.Where(a => a.DeceasedId == deceasedId.Value);

        if (!string.IsNullOrWhiteSpace(status))
            query = query.Where(a => a.Status == status);

        var total = await query.CountAsync();
        var items = await query
            .OrderByDescending(a => a.FuneralDateTime)
            .Skip((pageNumber - 1) * pageSize)
            .Take(pageSize)
            .Select(a => ToResponse(a))
            .ToListAsync();

        return PagedResponse<AppointmentResponse>.Create(items, total, pageNumber, pageSize);
    }

    public async Task<AppointmentResponse?> GetByIdAsync(int id)
    {
        var a = await _db.Appointments
            .Include(x => x.Deceased)
            .Include(x => x.Mosque)
            .Include(x => x.Cemetery)
            .Include(x => x.Imam)
            .Include(x => x.GraveSite)
            .FirstOrDefaultAsync(x => x.Id == id);
        return a == null ? null : ToResponse(a);
    }

    public async Task<AppointmentResponse> CreateAsync(AppointmentRequest request, string userId)
    {
        var appointment = new Appointment
        {
            DeceasedId = request.DeceasedId,
            MosqueId = request.MosqueId,
            CemeteryId = request.CemeteryId,
            ImamId = request.ImamId,
            GraveSiteId = request.GraveSiteId,
            FuneralDateTime = request.FuneralDateTime,
            Note = request.Note,
            Status = "Scheduled",
            CreatedByUserId = userId
        };

        _db.Appointments.Add(appointment);
        await _db.SaveChangesAsync();

        await _db.Entry(appointment).Reference(a => a.Deceased).LoadAsync();
        await _db.Entry(appointment).Reference(a => a.Mosque).LoadAsync();
        await _db.Entry(appointment).Reference(a => a.Cemetery).LoadAsync();

        Imam? imam = null;
        if (appointment.ImamId.HasValue)
        {
            await _db.Entry(appointment).Reference(a => a.Imam).LoadAsync();
            imam = appointment.Imam;
        }

        await _publishEndpoint.Publish(new AppointmentConfirmedMessage(
            appointment.Id,
            appointment.Deceased.Id,
            $"{appointment.Deceased.FirstName} {appointment.Deceased.LastName}",
            appointment.Mosque.Name,
            appointment.Cemetery.Name,
            imam != null ? $"{imam.FirstName} {imam.LastName}" : null,
            appointment.FuneralDateTime,
            appointment.Deceased.ContactPersonEmail ?? string.Empty,
            appointment.Deceased.ContactPersonPhone
        ));

        if (imam?.Email != null)
        {
            await _publishEndpoint.Publish(new ImamNotificationMessage(
                imam.Id,
                $"{imam.FirstName} {imam.LastName}",
                imam.Email,
                appointment.Id,
                $"{appointment.Deceased.FirstName} {appointment.Deceased.LastName}",
                appointment.Mosque.Name,
                appointment.Cemetery.Name,
                appointment.FuneralDateTime
            ));
        }

        return ToResponse(appointment);
    }

    public async Task<bool> UpdateStatusAsync(int id, string status)
    {
        var appointment = await _db.Appointments.FindAsync(id);
        if (appointment == null) return false;

        appointment.Status = status;
        await _db.SaveChangesAsync();
        return true;
    }

    public async Task<bool> DeleteAsync(int id)
    {
        var appointment = await _db.Appointments.FindAsync(id);
        if (appointment == null) return false;
        _db.Appointments.Remove(appointment);
        await _db.SaveChangesAsync();
        return true;
    }

    private static AppointmentResponse ToResponse(Appointment a) => new()
    {
        Id = a.Id,
        DeceasedId = a.DeceasedId,
        DeceasedFullName = a.Deceased != null ? $"{a.Deceased.FirstName} {a.Deceased.LastName}" : string.Empty,
        MosqueId = a.MosqueId,
        MosqueName = a.Mosque?.Name ?? string.Empty,
        CemeteryId = a.CemeteryId,
        CemeteryName = a.Cemetery?.Name ?? string.Empty,
        ImamId = a.ImamId,
        ImamFullName = a.Imam != null ? $"{a.Imam.FirstName} {a.Imam.LastName}" : null,
        GraveSiteId = a.GraveSiteId,
        GravePlotNumber = a.GraveSite?.PlotNumber,
        FuneralDateTime = a.FuneralDateTime,
        Status = a.Status,
        Note = a.Note,
        CreatedAt = a.CreatedAt
    };
}

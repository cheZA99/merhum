using MassTransit;
using MerhumAPI.Common;
using MerhumAPI.Data;
using MerhumAPI.DTOs.Appointment;
using MerhumContracts;
using MerhumAPI.Models;
using Microsoft.EntityFrameworkCore;

namespace MerhumAPI.Services;

public class AppointmentService : IAppointmentService
{
    private readonly ApplicationDbContext _db;
    private readonly IPublishEndpoint _publishEndpoint;
    private readonly INotificationService _notificationService;

    public AppointmentService(ApplicationDbContext db, IPublishEndpoint publishEndpoint, INotificationService notificationService)
    {
        _db = db;
        _publishEndpoint = publishEndpoint;
        _notificationService = notificationService;
    }

    public async Task<PagedResponse<AppointmentResponse>> GetAllAsync(int? deceasedId, AppointmentStatus? status, int? mosqueId, int? imamId, int? cityId, DateTime? dateFrom, DateTime? dateTo, int pageNumber, int pageSize, string? scopeToUserId)
    {
        (pageNumber, pageSize) = Pagination.Normalize(pageNumber, pageSize);

        var query = _db.Appointments
            .Include(a => a.Deceased).ThenInclude(d => d.City)
            .Include(a => a.Mosque)
            .Include(a => a.Cemetery)
            .Include(a => a.Imam)
            .Include(a => a.GraveSite)
            .AsQueryable();

        // null means an unscoped read, otherwise a family sees its own funerals and an imam the ones assigned to him
        if (scopeToUserId != null)
            query = query.Where(a => a.Deceased.UserId == scopeToUserId || (a.Imam != null && a.Imam.UserId == scopeToUserId));

        if (deceasedId.HasValue)
            query = query.Where(a => a.DeceasedId == deceasedId.Value);

        if (status.HasValue)
            query = query.Where(a => a.Status == status.Value);

        if (mosqueId.HasValue)
            query = query.Where(a => a.MosqueId == mosqueId.Value);

        if (imamId.HasValue)
            query = query.Where(a => a.ImamId == imamId.Value);

        if (cityId.HasValue)
            query = query.Where(a => a.Deceased.CityId == cityId.Value);

        if (dateFrom.HasValue)
            query = query.Where(a => a.FuneralDateTime >= dateFrom.Value);

        if (dateTo.HasValue)
            query = query.Where(a => a.FuneralDateTime <= dateTo.Value);

        var total = await query.CountAsync();
        var items = await query
            .OrderByDescending(a => a.FuneralDateTime)
            .Skip((pageNumber - 1) * pageSize)
            .Take(pageSize)
            .Select(a => ToResponse(a))
            .ToListAsync();

        return PagedResponse<AppointmentResponse>.Create(items, total, pageNumber, pageSize);
    }

    public async Task<AppointmentResponse?> GetByIdAsync(int id, string? scopeToUserId)
    {
        var a = await _db.Appointments
            .Include(x => x.Deceased).ThenInclude(d => d.City)
            .Include(x => x.Mosque)
            .Include(x => x.Cemetery)
            .Include(x => x.Imam)
            .Include(x => x.GraveSite)
            .FirstOrDefaultAsync(x => x.Id == id);

        if (a == null) return null;
        if (scopeToUserId != null && a.Deceased.UserId != scopeToUserId && a.Imam?.UserId != scopeToUserId) return null;

        return ToResponse(a);
    }

    public async Task<AppointmentResponse> CreateAsync(AppointmentRequest request, string userId)
    {
        await ValidateScheduleAsync(request, null);

        var appointment = new Appointment
        {
            DeceasedId = request.DeceasedId,
            MosqueId = request.MosqueId,
            CemeteryId = request.CemeteryId,
            ImamId = request.ImamId,
            GraveSiteId = request.GraveSiteId,
            FuneralDateTime = request.FuneralDateTime,
            Note = request.Note,
            Status = AppointmentStatus.Scheduled,
            CreatedByUserId = userId
        };

        _db.Appointments.Add(appointment);
        await ReserveGraveSiteAsync(appointment.GraveSiteId, null);
        await _db.SaveChangesAsync();

        await _db.Entry(appointment).Reference(a => a.Deceased).LoadAsync();
        await _db.Entry(appointment.Deceased).Reference(d => d.City).LoadAsync();
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

        await _notificationService.CreateForDeceasedAsync(
            appointment.DeceasedId,
            "Zakazana dženaza",
            $"Dženaza za {appointment.Deceased.FirstName} {appointment.Deceased.LastName} je zakazana za {appointment.FuneralDateTime:dd.MM.yyyy. HH:mm}.");

        return ToResponse(appointment);
    }

    public async Task<AppointmentResponse?> UpdateAsync(int id, AppointmentRequest request)
    {
        var appointment = await _db.Appointments.FindAsync(id);
        if (appointment == null) return null;

        await ValidateScheduleAsync(request, id);
        await ReserveGraveSiteAsync(request.GraveSiteId, appointment.GraveSiteId);

        appointment.DeceasedId = request.DeceasedId;
        appointment.MosqueId = request.MosqueId;
        appointment.CemeteryId = request.CemeteryId;
        appointment.ImamId = request.ImamId;
        appointment.GraveSiteId = request.GraveSiteId;
        appointment.FuneralDateTime = request.FuneralDateTime;
        appointment.Note = request.Note;

        await _db.SaveChangesAsync();

        await _db.Entry(appointment).Reference(a => a.Deceased).LoadAsync();
        await _db.Entry(appointment.Deceased).Reference(d => d.City).LoadAsync();
        await _db.Entry(appointment).Reference(a => a.Mosque).LoadAsync();
        await _db.Entry(appointment).Reference(a => a.Cemetery).LoadAsync();
        if (appointment.ImamId.HasValue)
            await _db.Entry(appointment).Reference(a => a.Imam).LoadAsync();
        if (appointment.GraveSiteId.HasValue)
            await _db.Entry(appointment).Reference(a => a.GraveSite).LoadAsync();

        return ToResponse(appointment);
    }

    public async Task<StatusChangeResult> UpdateStatusAsync(int id, AppointmentStatus status, string changedByUserId, string? reason)
    {
        var appointment = await _db.Appointments.FindAsync(id);
        if (appointment == null) return StatusChangeResult.NotFound;

        if (!StatusTransitions.AppointmentAllows(appointment.Status, status))
            return StatusChangeResult.NotAllowed;

        appointment.Status = status;

        if (status == AppointmentStatus.Cancelled)
        {
            appointment.CancelledAt = DateTime.UtcNow;
            appointment.CancelledByUserId = changedByUserId;
            appointment.CancellationReason = reason;
            await ReleaseGraveSiteAsync(appointment.GraveSiteId);
        }

        await _db.SaveChangesAsync();

        if (status == AppointmentStatus.Cancelled)
            await _notificationService.CreateForDeceasedAsync(appointment.DeceasedId, "Dženaza otkazana", "Zakazana dženaza je otkazana.");
        else if (status == AppointmentStatus.Held)
            await _notificationService.CreateForDeceasedAsync(appointment.DeceasedId, "Dženaza obavljena", "Dženaza je evidentirana kao obavljena.");

        return StatusChangeResult.Ok;
    }

    // a mosque cannot hold two funerals closer together than this
    private static readonly TimeSpan MosqueSlot = TimeSpan.FromHours(2);

    private async Task ValidateScheduleAsync(AppointmentRequest request, int? appointmentId)
    {
        var from = request.FuneralDateTime - MosqueSlot;
        var to = request.FuneralDateTime + MosqueSlot;

        var clash = await _db.Appointments.AnyAsync(a => a.MosqueId == request.MosqueId
            && a.Status != AppointmentStatus.Cancelled
            && (appointmentId == null || a.Id != appointmentId)
            && a.FuneralDateTime > from
            && a.FuneralDateTime < to);

        if (clash)
            throw new InvalidOperationException("Mesdžid već ima zakazan termin unutar dva sata od tog vremena.");

        if (request.ImamId.HasValue)
        {
            var imamServesMosque = await _db.Imams.AnyAsync(i => i.Id == request.ImamId.Value && i.MosqueId == request.MosqueId);
            if (!imamServesMosque)
                throw new InvalidOperationException("Odabrani imam ne pripada odabranom mesdžidu.");
        }

        if (request.GraveSiteId.HasValue)
        {
            var site = await _db.GraveSites.FirstOrDefaultAsync(g => g.Id == request.GraveSiteId.Value)
                ?? throw new KeyNotFoundException("Mezarsko mjesto nije pronađeno.");

            if (site.CemeteryId != request.CemeteryId)
                throw new InvalidOperationException("Mezarsko mjesto ne pripada odabranom mezarju.");

            var alreadyHeldHere = appointmentId != null
                && await _db.Appointments.AnyAsync(a => a.Id == appointmentId && a.GraveSiteId == site.Id);

            if (!alreadyHeldHere && (site.Status != GraveSiteStatus.Available || site.DeceasedId != null))
                throw new InvalidOperationException("Odabrano mezarsko mjesto nije slobodno.");
        }
    }

    // a booked site stops being offered to anyone else until the funeral is held or called off
    private async Task ReserveGraveSiteAsync(int? graveSiteId, int? previousGraveSiteId)
    {
        if (previousGraveSiteId == graveSiteId) return;

        await ReleaseGraveSiteAsync(previousGraveSiteId);

        if (graveSiteId == null) return;

        var site = await _db.GraveSites.FindAsync(graveSiteId.Value);
        if (site != null && site.Status == GraveSiteStatus.Available)
            site.Status = GraveSiteStatus.Reserved;
    }

    private async Task ReleaseGraveSiteAsync(int? graveSiteId)
    {
        if (graveSiteId == null) return;

        var site = await _db.GraveSites.FindAsync(graveSiteId.Value);
        if (site != null && site.Status == GraveSiteStatus.Reserved && site.DeceasedId == null)
            site.Status = GraveSiteStatus.Available;
    }

    private static AppointmentResponse ToResponse(Appointment a) => new()
    {
        Id = a.Id,
        DeceasedId = a.DeceasedId,
        DeceasedFullName = a.Deceased != null ? $"{a.Deceased.FirstName} {a.Deceased.LastName}" : string.Empty,
        CityId = a.Deceased?.CityId,
        CityName = a.Deceased?.City?.Name,
        MosqueId = a.MosqueId,
        MosqueName = a.Mosque?.Name ?? string.Empty,
        CemeteryId = a.CemeteryId,
        CemeteryName = a.Cemetery?.Name ?? string.Empty,
        ImamId = a.ImamId,
        ImamFullName = a.Imam != null ? $"{a.Imam.FirstName} {a.Imam.LastName}" : null,
        MosqueAddress = a.Mosque?.Address,
        MosqueLatitude = a.Mosque?.Latitude,
        MosqueLongitude = a.Mosque?.Longitude,
        ContactPersonName = a.Deceased?.ContactPersonName,
        ContactPersonPhone = a.Deceased?.ContactPersonPhone,
        GraveSiteId = a.GraveSiteId,
        GravePlotNumber = a.GraveSite?.PlotNumber,
        FuneralDateTime = a.FuneralDateTime,
        Status = a.Status.ToString(),
        Note = a.Note,
        CreatedAt = a.CreatedAt
    };
}

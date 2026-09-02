using MassTransit;
using MerhumAPI.Common;
using MerhumAPI.Data;
using MerhumAPI.DTOs.Deceased;
using MerhumAPI.Messages;
using MerhumAPI.Models;
using Microsoft.EntityFrameworkCore;

namespace MerhumAPI.Services;

public class DeceasedService : IDeceasedService
{
    private readonly ApplicationDbContext _db;
    private readonly IPublishEndpoint _publishEndpoint;
    private readonly INotificationService _notificationService;

    public DeceasedService(ApplicationDbContext db, IPublishEndpoint publishEndpoint, INotificationService notificationService)
    {
        _db = db;
        _publishEndpoint = publishEndpoint;
        _notificationService = notificationService;
    }

    public async Task<PagedResponse<DeceasedResponse>> GetAllAsync(string? search, int? statusId, int? cityId, bool withoutGraveSite, int pageNumber, int pageSize)
    {
        (pageNumber, pageSize) = Pagination.Normalize(pageNumber, pageSize);

        var query = _db.Deceased
            .Include(d => d.City).ThenInclude(c => c.Country)
            .Include(d => d.ProcedureStatus)
            .Include(d => d.Obituary)
            .Include(d => d.User)
            .AsQueryable();

        if (!string.IsNullOrWhiteSpace(search))
            query = query.Where(d => (d.FirstName + " " + d.LastName).Contains(search));

        if (statusId.HasValue)
            query = query.Where(d => d.ProcedureStatusId == statusId.Value);

        if (cityId.HasValue)
            query = query.Where(d => d.CityId == cityId.Value);

        if (withoutGraveSite)
            query = query.Where(d => !_db.GraveSites.Any(g => g.DeceasedId == d.Id));

        query = query.OrderByDescending(d => d.CreatedAt);

        var total = await query.CountAsync();
        var items = await query
            .Skip((pageNumber - 1) * pageSize)
            .Take(pageSize)
            .Select(d => ToResponse(d))
            .ToListAsync();

        return PagedResponse<DeceasedResponse>.Create(items, total, pageNumber, pageSize);
    }

    public async Task<PagedResponse<DeceasedResponse>> GetMyAsync(string userId, int pageNumber, int pageSize)
    {
        (pageNumber, pageSize) = Pagination.Normalize(pageNumber, pageSize);

        var query = _db.Deceased
            .Include(d => d.City).ThenInclude(c => c.Country)
            .Include(d => d.ProcedureStatus)
            .Include(d => d.Obituary)
            .Include(d => d.User)
            .Where(d => d.UserId == userId)
            .OrderByDescending(d => d.CreatedAt);

        var total = await query.CountAsync();
        var items = await query
            .Skip((pageNumber - 1) * pageSize)
            .Take(pageSize)
            .Select(d => ToResponse(d))
            .ToListAsync();

        return PagedResponse<DeceasedResponse>.Create(items, total, pageNumber, pageSize);
    }

    public async Task<DeceasedResponse?> GetByIdAsync(int id)
    {
        var d = await _db.Deceased
            .Include(x => x.City).ThenInclude(c => c.Country)
            .Include(x => x.ProcedureStatus)
            .Include(x => x.Obituary)
            .Include(x => x.User)
            .FirstOrDefaultAsync(x => x.Id == id);

        return d == null ? null : ToResponse(d);
    }

    public async Task<DeceasedResponse> CreateAsync(DeceasedRequest request, string userId)
    {
        var deceased = new Deceased
        {
            FirstName = request.FirstName,
            LastName = request.LastName,
            DateOfBirth = request.DateOfBirth,
            DateOfDeath = request.DateOfDeath,
            PlaceOfDeath = request.PlaceOfDeath,
            PhotoUrl = request.PhotoUrl,
            ContactPersonName = request.ContactPersonName,
            ContactPersonPhone = request.ContactPersonPhone,
            ContactPersonEmail = request.ContactPersonEmail,
            CityId = request.CityId,
            ProcedureStatusId = request.ProcedureStatusId,
            UserId = userId
        };

        _db.Deceased.Add(deceased);
        await _db.SaveChangesAsync();

        await _publishEndpoint.Publish(new FuneralRegisteredMessage(
            deceased.Id,
            $"{deceased.FirstName} {deceased.LastName}",
            deceased.ContactPersonEmail ?? string.Empty,
            deceased.ContactPersonName,
            deceased.ContactPersonPhone,
            deceased.CreatedAt
        ));

        return new DeceasedResponse
        {
            Id = deceased.Id,
            FirstName = deceased.FirstName,
            LastName = deceased.LastName,
            DateOfBirth = deceased.DateOfBirth,
            DateOfDeath = deceased.DateOfDeath,
            PlaceOfDeath = deceased.PlaceOfDeath,
            PhotoUrl = deceased.PhotoUrl,
            ContactPersonName = deceased.ContactPersonName,
            ContactPersonPhone = deceased.ContactPersonPhone,
            ContactPersonEmail = deceased.ContactPersonEmail,
            CityName = string.Empty,
            CountryName = string.Empty,
            ProcedureStatusId = deceased.ProcedureStatusId,
            ProcedureStatusName = string.Empty,
            CreatedAt = deceased.CreatedAt
        };
    }

    public async Task<bool> UpdateAsync(int id, DeceasedRequest request)
    {
        var deceased = await _db.Deceased.FindAsync(id);
        if (deceased == null) return false;

        deceased.FirstName = request.FirstName;
        deceased.LastName = request.LastName;
        deceased.DateOfBirth = request.DateOfBirth;
        deceased.DateOfDeath = request.DateOfDeath;
        deceased.PlaceOfDeath = request.PlaceOfDeath;
        deceased.PhotoUrl = request.PhotoUrl;
        deceased.ContactPersonName = request.ContactPersonName;
        deceased.ContactPersonPhone = request.ContactPersonPhone;
        deceased.ContactPersonEmail = request.ContactPersonEmail;
        deceased.CityId = request.CityId;
        deceased.ProcedureStatusId = request.ProcedureStatusId;

        await _db.SaveChangesAsync();
        return true;
    }

    public async Task<bool> UpdateStatusAsync(int id, int statusId, string? note, string changedByUserId)
    {
        var deceased = await _db.Deceased.FindAsync(id);
        if (deceased == null) return false;

        deceased.ProcedureStatusId = statusId;

        _db.StatusHistories.Add(new StatusHistory
        {
            DeceasedId = id,
            StatusId = statusId,
            Note = note,
            ChangedByUserId = changedByUserId
        });

        await _db.SaveChangesAsync();

        await _notificationService.CreateForDeceasedAsync(id, "Promjena statusa procedure", "Status procedure za preminulog je ažuriran.");

        return true;
    }

    public async Task<string?> UploadPhotoAsync(int id, IFormFile file)
    {
        var deceased = await _db.Deceased.FindAsync(id);
        if (deceased == null) return null;

        var ext = Path.GetExtension(file.FileName).ToLowerInvariant();
        var folder = Path.Combine("wwwroot", "uploads", "photos");
        Directory.CreateDirectory(folder);

        var fileName = $"deceased-{id}-{Guid.NewGuid():N}{ext}";
        var filePath = Path.Combine(folder, fileName);

        using (var stream = new FileStream(filePath, FileMode.Create))
            await file.CopyToAsync(stream);

        deceased.PhotoUrl = $"/uploads/photos/{fileName}";
        await _db.SaveChangesAsync();

        return deceased.PhotoUrl;
    }

    public async Task<bool> DeleteAsync(int id)
    {
        var deceased = await _db.Deceased.FindAsync(id);
        if (deceased == null) return false;

        _db.Deceased.Remove(deceased);
        await _db.SaveChangesAsync();
        return true;
    }

    public async Task<List<StatusHistoryResponse>> GetStatusHistoryAsync(int id)
    {
        return await _db.StatusHistories
            .Include(h => h.ProcedureStatus)
            .Include(h => h.ChangedByUser)
            .Where(h => h.DeceasedId == id)
            .OrderBy(h => h.ChangedAt)
            .Select(h => new StatusHistoryResponse
            {
                Id = h.Id,
                DeceasedId = h.DeceasedId,
                StatusId = h.StatusId,
                StatusName = h.ProcedureStatus.Name,
                Note = h.Note,
                ChangedAt = h.ChangedAt,
                ChangedByUsername = h.ChangedByUser.UserName ?? ""
            })
            .ToListAsync();
    }

    private static DeceasedResponse ToResponse(Deceased d) => new()
    {
        Id = d.Id,
        FirstName = d.FirstName,
        LastName = d.LastName,
        DateOfBirth = d.DateOfBirth,
        DateOfDeath = d.DateOfDeath,
        PlaceOfDeath = d.PlaceOfDeath,
        PhotoUrl = d.PhotoUrl,
        ContactPersonName = d.ContactPersonName,
        ContactPersonPhone = d.ContactPersonPhone,
        ContactPersonEmail = d.ContactPersonEmail,
        CityName = d.City.Name,
        CountryName = d.City.Country.Name,
        ProcedureStatusId = d.ProcedureStatusId,
        ProcedureStatusName = d.ProcedureStatus.Name,
        CreatedAt = d.CreatedAt,
        ObituarySlug = d.Obituary != null ? d.Obituary.UniqueSlug : null,
        CityId = d.CityId,
        CreatedByUsername = d.User.UserName ?? ""
    };
}

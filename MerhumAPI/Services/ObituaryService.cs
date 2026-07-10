using MassTransit;
using MerhumAPI.Common;
using MerhumAPI.Data;
using MerhumAPI.DTOs.Condolence;
using MerhumAPI.DTOs.Obituary;
using MerhumAPI.Helpers;
using MerhumAPI.Messages;
using MerhumAPI.Models;
using Microsoft.EntityFrameworkCore;

namespace MerhumAPI.Services;

public class ObituaryService : IObituaryService
{
    private readonly ApplicationDbContext _db;
    private readonly IPublishEndpoint _publishEndpoint;
    private readonly IConfiguration _configuration;

    public ObituaryService(ApplicationDbContext db, IPublishEndpoint publishEndpoint, IConfiguration configuration)
    {
        _db = db;
        _publishEndpoint = publishEndpoint;
        _configuration = configuration;
    }

    public async Task<PagedResponse<ObituaryResponse>> GetAllAsync(bool? isPublic, bool? isActive, string? deceasedName, int pageNumber, int pageSize)
    {
        (pageNumber, pageSize) = Pagination.Normalize(pageNumber, pageSize);

        var query = _db.Obituaries
            .Include(o => o.Deceased)
            .Include(o => o.CreatedByUser)
            .Include(o => o.Condolences)
            .AsQueryable();

        if (isPublic.HasValue)
            query = query.Where(o => o.IsPublic == isPublic.Value);

        if (isActive.HasValue)
            query = query.Where(o => o.IsActive == isActive.Value);

        if (!string.IsNullOrWhiteSpace(deceasedName))
            query = query.Where(o => (o.Deceased.FirstName + " " + o.Deceased.LastName).Contains(deceasedName));

        var total = await query.CountAsync();
        var items = await query
            .OrderByDescending(o => o.CreatedAt)
            .Skip((pageNumber - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        return PagedResponse<ObituaryResponse>.Create(items.Select(MapToResponse).ToList(), total, pageNumber, pageSize);
    }

    public async Task<ObituaryResponse?> GetByIdAsync(int id)
    {
        var o = await _db.Obituaries
            .Include(x => x.Deceased).ThenInclude(d => d.City)
            .Include(x => x.Condolences)
            .Include(x => x.CreatedByUser)
            .FirstOrDefaultAsync(x => x.Id == id);
        return o == null ? null : MapToResponse(o);
    }

    public async Task<ObituaryResponse?> GetBySlugAsync(string slug)
    {
        var obituary = await _db.Obituaries
            .Include(o => o.Deceased).ThenInclude(d => d.City)
            .Include(o => o.Condolences.Where(c => c.IsApproved))
            .FirstOrDefaultAsync(o => o.UniqueSlug == slug && o.IsActive);

        if (obituary == null) return null;

        return MapToResponse(obituary);
    }

    public async Task<ObituaryResponse> CreateAsync(int deceasedId, bool isPublic, string userId)
    {
        var deceased = await _db.Deceased
            .Include(d => d.City)
            .FirstOrDefaultAsync(d => d.Id == deceasedId)
            ?? throw new KeyNotFoundException($"Deceased with id {deceasedId} not found.");

        var slug = GenerateSlug(deceased.FirstName, deceased.LastName, deceased.DateOfDeath);
        var baseUrl = _configuration["AppSettings:SmrtovnicaBaseUrl"] ?? "http://localhost:5000/smrtovnica";
        var obituaryUrl = $"{baseUrl}/{slug}";
        var qrCodeUrl = QRGenerator.GenerateAndSave(obituaryUrl, slug);

        var obituary = new Obituary
        {
            DeceasedId = deceasedId,
            UniqueSlug = slug,
            QrCodeUrl = qrCodeUrl,
            IsPublic = isPublic,
            CreatedByUserId = userId
        };

        _db.Obituaries.Add(obituary);
        await _db.SaveChangesAsync();

        // attach the loaded deceased so MapToResponse can fill name/date fields
        obituary.Deceased = deceased;

        await _publishEndpoint.Publish(new ObituaryCreatedMessage(
            obituary.Id,
            deceased.Id,
            $"{deceased.FirstName} {deceased.LastName}",
            slug,
            deceased.ContactPersonEmail ?? string.Empty,
            deceased.ContactPersonName,
            obituary.CreatedAt
        ));

        return MapToResponse(obituary);
    }

    public async Task<bool> UpdateAsync(int id, bool isPublic, bool isActive)
    {
        var obituary = await _db.Obituaries.FindAsync(id);
        if (obituary == null) return false;

        obituary.IsPublic = isPublic;
        obituary.IsActive = isActive;

        await _db.SaveChangesAsync();
        return true;
    }

    public async Task<bool> DeleteAsync(int id)
    {
        var obituary = await _db.Obituaries.FindAsync(id);
        if (obituary == null) return false;
        _db.Obituaries.Remove(obituary);
        await _db.SaveChangesAsync();
        return true;
    }

    public async Task IncrementViewCountAsync(int obituaryId)
    {
        await _db.Obituaries
            .Where(o => o.Id == obituaryId)
            .ExecuteUpdateAsync(s => s.SetProperty(o => o.ViewCount, o => o.ViewCount + 1));
    }

    private static string GenerateSlug(string firstName, string lastName, DateOnly dateOfDeath)
    {
        var normalized = $"{firstName}-{lastName}-{dateOfDeath:yyyy-MM-dd}"
            .ToLowerInvariant()
            .Replace(" ", "-")
            .Replace("č", "c").Replace("ć", "c").Replace("š", "s")
            .Replace("ž", "z").Replace("đ", "dj");
        return $"{normalized}-{Guid.NewGuid().ToString()[..8]}";
    }

    private static ObituaryResponse MapToResponse(Obituary o) => new()
    {
        Id = o.Id,
        DeceasedId = o.DeceasedId,
        DeceasedFullName = o.Deceased != null ? $"{o.Deceased.FirstName} {o.Deceased.LastName}" : string.Empty,
        DeceasedPhotoUrl = o.Deceased?.PhotoUrl,
        DeceasedDateOfDeath = o.Deceased?.DateOfDeath,
        UniqueSlug = o.UniqueSlug,
        QrCodeUrl = o.QrCodeUrl,
        ViewCount = o.ViewCount,
        IsPublic = o.IsPublic,
        IsActive = o.IsActive,
        CreatedAt = o.CreatedAt,
        CreatedByUsername = o.CreatedByUser?.UserName,
        CondolenceCount = o.Condolences.Count,
        ApprovedCondolenceCount = o.Condolences.Count(c => c.IsApproved),
        Condolences = o.Condolences.Select(c => new CondolenceResponse
        {
            Id = c.Id,
            ObituaryId = c.ObituaryId,
            AuthorName = c.AuthorName,
            Text = c.Text,
            IsApproved = c.IsApproved,
            CreatedAt = c.CreatedAt
        }).ToList()
    };
}

using MerhumAPI.Common;
using MerhumAPI.Data;
using MerhumAPI.DTOs.GraveSite;
using MerhumAPI.Helpers;
using MerhumAPI.Models;
using Microsoft.EntityFrameworkCore;

namespace MerhumAPI.Services;

public class GraveSiteService : IGraveSiteService
{
    private readonly ApplicationDbContext _db;

    public GraveSiteService(ApplicationDbContext db) => _db = db;

    public async Task<PagedResponse<GraveSiteResponse>> GetAllAsync(int? cemeteryId, string? status, int pageNumber, int pageSize)
    {
        (pageNumber, pageSize) = Pagination.Normalize(pageNumber, pageSize);

        var query = _db.GraveSites
            .Include(g => g.Cemetery)
            .Include(g => g.Section)
            .Include(g => g.Deceased)
            .AsQueryable();

        if (cemeteryId.HasValue)
            query = query.Where(g => g.CemeteryId == cemeteryId.Value);

        if (!string.IsNullOrWhiteSpace(status))
            query = query.Where(g => g.Status == status);

        var total = await query.CountAsync();
        var items = await query
            .OrderBy(g => g.CemeteryId).ThenBy(g => g.PlotNumber)
            .Skip((pageNumber - 1) * pageSize)
            .Take(pageSize)
            .Select(g => ToResponse(g))
            .ToListAsync();

        return PagedResponse<GraveSiteResponse>.Create(items, total, pageNumber, pageSize);
    }

    public async Task<GraveSiteResponse?> GetByIdAsync(int id)
    {
        var g = await _db.GraveSites
            .Include(x => x.Cemetery)
            .Include(x => x.Section)
            .Include(x => x.Deceased)
            .FirstOrDefaultAsync(x => x.Id == id);
        return g == null ? null : ToResponse(g);
    }

    public async Task<GraveSiteResponse> CreateAsync(GraveSiteRequest request)
    {
        var site = new GraveSite
        {
            CemeteryId = request.CemeteryId,
            SectionId = request.SectionId,
            PlotNumber = request.PlotNumber,
            Row = request.Row,
            Latitude = request.Latitude,
            Longitude = request.Longitude,
            Status = "Available"
        };
        _db.GraveSites.Add(site);
        await _db.SaveChangesAsync();
        await _db.Entry(site).Reference(g => g.Cemetery).LoadAsync();
        return ToResponse(site);
    }

    public async Task<bool> UpdateAsync(int id, GraveSiteRequest request)
    {
        var site = await _db.GraveSites.FindAsync(id);
        if (site == null) return false;

        site.CemeteryId = request.CemeteryId;
        site.SectionId = request.SectionId;
        site.PlotNumber = request.PlotNumber;
        site.Row = request.Row;
        site.Latitude = request.Latitude;
        site.Longitude = request.Longitude;

        await _db.SaveChangesAsync();
        return true;
    }

    public async Task<bool> AssignDeceasedAsync(int id, int deceasedId, string baseUrl)
    {
        var site = await _db.GraveSites.FindAsync(id);
        if (site == null) return false;

        var alreadyAssigned = await _db.GraveSites
            .AnyAsync(g => g.DeceasedId == deceasedId && g.Id != id);
        if (alreadyAssigned)
            throw new InvalidOperationException("Ovaj preminuli je već dodijeljen drugom mezarskom mjestu.");

        site.DeceasedId = deceasedId;
        site.Status = "Occupied";

        var qrUrl = $"{baseUrl}/api/gravesite/{id}";
        site.QrCodeUrl = QRGenerator.GenerateAndSave(qrUrl, $"gravesite-{id}");

        await _db.SaveChangesAsync();
        return true;
    }

    public async Task<bool> UnassignDeceasedAsync(int id)
    {
        var site = await _db.GraveSites.FindAsync(id);
        if (site == null) return false;
        site.DeceasedId = null;
        site.Status = "Available";
        await _db.SaveChangesAsync();
        return true;
    }

    public async Task<bool> UpdateStatusAsync(int id, string status)
    {
        var site = await _db.GraveSites.FindAsync(id);
        if (site == null) return false;
        site.Status = status;
        await _db.SaveChangesAsync();
        return true;
    }

    public async Task<bool> DeleteAsync(int id)
    {
        var site = await _db.GraveSites.FindAsync(id);
        if (site == null) return false;
        _db.GraveSites.Remove(site);
        await _db.SaveChangesAsync();
        return true;
    }

    private static GraveSiteResponse ToResponse(GraveSite g) => new()
    {
        Id = g.Id,
        CemeteryId = g.CemeteryId,
        CemeteryName = g.Cemetery?.Name ?? string.Empty,
        SectionId = g.SectionId,
        SectionName = g.Section?.Name,
        PlotNumber = g.PlotNumber,
        Row = g.Row,
        Status = g.Status,
        DeceasedId = g.DeceasedId,
        DeceasedFullName = g.Deceased != null ? $"{g.Deceased.FirstName} {g.Deceased.LastName}" : null,
        QrCodeUrl = g.QrCodeUrl,
        Latitude = g.Latitude,
        Longitude = g.Longitude
    };
}

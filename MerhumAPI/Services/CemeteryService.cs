using MerhumAPI.Common;
using MerhumAPI.Data;
using MerhumAPI.DTOs.Cemetery;
using MerhumAPI.Models;
using Microsoft.EntityFrameworkCore;

namespace MerhumAPI.Services;

public class CemeteryService : ICemeteryService
{
    private readonly ApplicationDbContext _db;

    public CemeteryService(ApplicationDbContext db) => _db = db;

    public async Task<PagedResponse<CemeteryResponse>> GetAllAsync(string? search, int? majlisId, int? muftiateId, int pageNumber, int pageSize)
    {
        (pageNumber, pageSize) = Pagination.Normalize(pageNumber, pageSize);

        var query = _db.Cemeteries.Include(c => c.City).Include(c => c.Majlis).ThenInclude(m => m.Muftiate).AsQueryable();

        if (!string.IsNullOrWhiteSpace(search))
            query = query.Where(c => c.Name.Contains(search) || c.Address.Contains(search));

        if (majlisId.HasValue)
            query = query.Where(c => c.MajlisId == majlisId.Value);

        if (muftiateId.HasValue)
            query = query.Where(c => c.Majlis.MuftiateId == muftiateId.Value);

        var total = await query.CountAsync();
        var items = await query
            .OrderBy(c => c.Name)
            .Skip((pageNumber - 1) * pageSize)
            .Take(pageSize)
            .Select(c => new CemeteryResponse
            {
                Id = c.Id,
                Name = c.Name,
                Address = c.Address,
                CityId = c.CityId,
                CityName = c.City != null ? c.City.Name : string.Empty,
                MajlisId = c.MajlisId,
                MajlisName = c.Majlis != null ? c.Majlis.Name : string.Empty,
                MuftiateId = c.Majlis != null ? c.Majlis.MuftiateId : 0,
                MuftiateName = c.Majlis != null && c.Majlis.Muftiate != null ? c.Majlis.Muftiate.Name : string.Empty,
                TotalPlaces = c.TotalPlaces,
                OccupiedPlaces = _db.GraveSites.Count(g => g.CemeteryId == c.Id && g.Status == GraveSiteStatus.Occupied),
                AvailablePlaces = _db.GraveSites.Count(g => g.CemeteryId == c.Id && g.Status == GraveSiteStatus.Available),
                ReservedPlaces = _db.GraveSites.Count(g => g.CemeteryId == c.Id && g.Status == GraveSiteStatus.Reserved),
                FillPercentage = c.TotalPlaces > 0
                    ? Math.Round((double)_db.GraveSites.Count(g => g.CemeteryId == c.Id && g.Status == GraveSiteStatus.Occupied) / c.TotalPlaces * 100, 1)
                    : 0.0,
                Latitude = c.Latitude,
                Longitude = c.Longitude,
                IsActive = c.IsActive
            })
            .ToListAsync();

        return PagedResponse<CemeteryResponse>.Create(items, total, pageNumber, pageSize);
    }

    public async Task<CemeteryResponse?> GetByIdAsync(int id)
    {
        var c = await _db.Cemeteries.Include(x => x.City).Include(x => x.Majlis).ThenInclude(m => m.Muftiate).FirstOrDefaultAsync(x => x.Id == id);
        if (c == null) return null;

        var occupied = await _db.GraveSites.CountAsync(g => g.CemeteryId == id && g.Status == GraveSiteStatus.Occupied);
        var available = await _db.GraveSites.CountAsync(g => g.CemeteryId == id && g.Status == GraveSiteStatus.Available);
        var reserved = await _db.GraveSites.CountAsync(g => g.CemeteryId == id && g.Status == GraveSiteStatus.Reserved);

        return new CemeteryResponse
        {
            Id = c.Id,
            Name = c.Name,
            Address = c.Address,
            CityId = c.CityId,
            CityName = c.City?.Name ?? string.Empty,
            MajlisId = c.MajlisId,
            MajlisName = c.Majlis?.Name ?? string.Empty,
            MuftiateId = c.Majlis?.MuftiateId ?? 0,
            MuftiateName = c.Majlis?.Muftiate?.Name ?? string.Empty,
            TotalPlaces = c.TotalPlaces,
            OccupiedPlaces = occupied,
            AvailablePlaces = available,
            ReservedPlaces = reserved,
            FillPercentage = c.TotalPlaces > 0 ? Math.Round((double)occupied / c.TotalPlaces * 100, 1) : 0.0,
            Latitude = c.Latitude,
            Longitude = c.Longitude,
            IsActive = c.IsActive
        };
    }

    public async Task<CemeteryResponse> CreateAsync(CemeteryRequest request)
    {
        var cemetery = new Cemetery
        {
            Name = request.Name,
            Address = request.Address,
            CityId = request.CityId,
            MajlisId = request.MajlisId,
            TotalPlaces = request.TotalPlaces,
            Latitude = request.Latitude,
            Longitude = request.Longitude,
            IsActive = request.IsActive
        };
        _db.Cemeteries.Add(cemetery);
        await _db.SaveChangesAsync();
        await _db.Entry(cemetery).Reference(c => c.City).LoadAsync();
        await _db.Entry(cemetery).Reference(c => c.Majlis).Query().Include(m => m.Muftiate).LoadAsync();
        return ToResponse(cemetery);
    }

    public async Task<bool> UpdateAsync(int id, CemeteryRequest request)
    {
        var cemetery = await _db.Cemeteries.FindAsync(id);
        if (cemetery == null) return false;

        cemetery.Name = request.Name;
        cemetery.Address = request.Address;
        cemetery.CityId = request.CityId;
        cemetery.MajlisId = request.MajlisId;
        cemetery.TotalPlaces = request.TotalPlaces;
        cemetery.Latitude = request.Latitude;
        cemetery.Longitude = request.Longitude;
        cemetery.IsActive = request.IsActive;

        await _db.SaveChangesAsync();
        return true;
    }

    public async Task<bool> DeleteAsync(int id)
    {
        var cemetery = await _db.Cemeteries.FindAsync(id);
        if (cemetery == null) return false;
        _db.Cemeteries.Remove(cemetery);
        await _db.SaveChangesAsync();
        return true;
    }

    private static CemeteryResponse ToResponse(Cemetery c) => new()
    {
        Id = c.Id,
        Name = c.Name,
        Address = c.Address,
        CityId = c.CityId,
        CityName = c.City?.Name ?? string.Empty,
        MajlisId = c.MajlisId,
        MajlisName = c.Majlis?.Name ?? string.Empty,
        MuftiateId = c.Majlis?.MuftiateId ?? 0,
        MuftiateName = c.Majlis?.Muftiate?.Name ?? string.Empty,
        TotalPlaces = c.TotalPlaces,
        Latitude = c.Latitude,
        Longitude = c.Longitude,
        IsActive = c.IsActive
    };
}

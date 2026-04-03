using MerhumAPI.Common;
using MerhumAPI.Data;
using MerhumAPI.DTOs.Mosque;
using MerhumAPI.Models;
using Microsoft.EntityFrameworkCore;

namespace MerhumAPI.Services;

public class MosqueService : IMosqueService
{
    private readonly ApplicationDbContext _db;

    public MosqueService(ApplicationDbContext db) => _db = db;

    public async Task<PagedResponse<MosqueResponse>> GetAllAsync(string? search, int pageNumber, int pageSize)
    {
        var query = _db.Mosques
            .Include(m => m.City)
            .AsQueryable();

        if (!string.IsNullOrWhiteSpace(search))
            query = query.Where(m => m.Name.Contains(search) || m.Address.Contains(search));

        var total = await query.CountAsync();
        var items = await query
            .OrderBy(m => m.Name)
            .Skip((pageNumber - 1) * pageSize)
            .Take(pageSize)
            .Select(m => ToResponse(m))
            .ToListAsync();

        return PagedResponse<MosqueResponse>.Create(items, total, pageNumber, pageSize);
    }

    public async Task<MosqueResponse?> GetByIdAsync(int id)
    {
        var m = await _db.Mosques.Include(x => x.City).FirstOrDefaultAsync(x => x.Id == id);
        return m == null ? null : ToResponse(m);
    }

    public async Task<MosqueResponse> CreateAsync(MosqueRequest request)
    {
        var mosque = new Mosque
        {
            Name = request.Name,
            Address = request.Address,
            CityId = request.CityId,
            Phone = request.Phone,
            Email = request.Email,
            Capacity = request.Capacity,
            Latitude = request.Latitude,
            Longitude = request.Longitude,
            IsActive = request.IsActive
        };
        _db.Mosques.Add(mosque);
        await _db.SaveChangesAsync();
        await _db.Entry(mosque).Reference(m => m.City).LoadAsync();
        return ToResponse(mosque);
    }

    public async Task<bool> UpdateAsync(int id, MosqueRequest request)
    {
        var mosque = await _db.Mosques.FindAsync(id);
        if (mosque == null) return false;

        mosque.Name = request.Name;
        mosque.Address = request.Address;
        mosque.CityId = request.CityId;
        mosque.Phone = request.Phone;
        mosque.Email = request.Email;
        mosque.Capacity = request.Capacity;
        mosque.Latitude = request.Latitude;
        mosque.Longitude = request.Longitude;
        mosque.IsActive = request.IsActive;

        await _db.SaveChangesAsync();
        return true;
    }

    public async Task<bool> DeleteAsync(int id)
    {
        var mosque = await _db.Mosques.FindAsync(id);
        if (mosque == null) return false;
        _db.Mosques.Remove(mosque);
        await _db.SaveChangesAsync();
        return true;
    }

    private static MosqueResponse ToResponse(Mosque m) => new()
    {
        Id = m.Id,
        Name = m.Name,
        Address = m.Address,
        CityId = m.CityId,
        CityName = m.City?.Name ?? string.Empty,
        Phone = m.Phone,
        Email = m.Email,
        Capacity = m.Capacity,
        Latitude = m.Latitude,
        Longitude = m.Longitude,
        IsActive = m.IsActive
    };
}

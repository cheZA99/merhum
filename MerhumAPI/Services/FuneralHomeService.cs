using MerhumAPI.Common;
using MerhumAPI.Data;
using MerhumAPI.DTOs.FuneralHome;
using MerhumAPI.Models;
using Microsoft.EntityFrameworkCore;

namespace MerhumAPI.Services;

public class FuneralHomeService : IFuneralHomeService
{
    private readonly ApplicationDbContext _db;

    public FuneralHomeService(ApplicationDbContext db) => _db = db;

    public async Task<PagedResponse<FuneralHomeResponse>> GetAllAsync(string? search, int pageNumber, int pageSize)
    {
        (pageNumber, pageSize) = Pagination.Normalize(pageNumber, pageSize);

        var query = _db.FuneralHomes.Include(f => f.City).AsQueryable();

        if (!string.IsNullOrWhiteSpace(search))
            query = query.Where(f => f.Name.Contains(search) || f.Address.Contains(search));

        var total = await query.CountAsync();
        var items = await query
            .OrderBy(f => f.Name)
            .Skip((pageNumber - 1) * pageSize)
            .Take(pageSize)
            .Select(f => ToResponse(f))
            .ToListAsync();

        return PagedResponse<FuneralHomeResponse>.Create(items, total, pageNumber, pageSize);
    }

    public async Task<FuneralHomeResponse?> GetByIdAsync(int id)
    {
        var f = await _db.FuneralHomes.Include(x => x.City).FirstOrDefaultAsync(x => x.Id == id);
        return f == null ? null : ToResponse(f);
    }

    public async Task<FuneralHomeResponse> CreateAsync(FuneralHomeRequest request)
    {
        var home = new FuneralHome
        {
            Name = request.Name,
            Address = request.Address,
            CityId = request.CityId,
            Phone = request.Phone,
            Email = request.Email,
            LicenseNumber = request.LicenseNumber,
            IsActive = request.IsActive
        };
        _db.FuneralHomes.Add(home);
        await _db.SaveChangesAsync();
        await _db.Entry(home).Reference(f => f.City).LoadAsync();
        return ToResponse(home);
    }

    public async Task<bool> UpdateAsync(int id, FuneralHomeRequest request)
    {
        var home = await _db.FuneralHomes.FindAsync(id);
        if (home == null) return false;

        home.Name = request.Name;
        home.Address = request.Address;
        home.CityId = request.CityId;
        home.Phone = request.Phone;
        home.Email = request.Email;
        home.LicenseNumber = request.LicenseNumber;
        home.IsActive = request.IsActive;

        await _db.SaveChangesAsync();
        return true;
    }

    public async Task<bool> DeleteAsync(int id)
    {
        var home = await _db.FuneralHomes.FindAsync(id);
        if (home == null) return false;
        _db.FuneralHomes.Remove(home);
        await _db.SaveChangesAsync();
        return true;
    }

    private static FuneralHomeResponse ToResponse(FuneralHome f) => new()
    {
        Id = f.Id,
        Name = f.Name,
        Address = f.Address,
        CityId = f.CityId,
        CityName = f.City?.Name ?? string.Empty,
        Phone = f.Phone,
        Email = f.Email,
        LicenseNumber = f.LicenseNumber,
        IsActive = f.IsActive
    };
}

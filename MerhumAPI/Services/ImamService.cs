using MerhumAPI.Common;
using MerhumAPI.Data;
using MerhumAPI.DTOs.Imam;
using MerhumAPI.Models;
using Microsoft.EntityFrameworkCore;

namespace MerhumAPI.Services;

public class ImamService : IImamService
{
    private readonly ApplicationDbContext _db;

    public ImamService(ApplicationDbContext db) => _db = db;

    public async Task<PagedResponse<ImamResponse>> GetAllAsync(int? mosqueId, bool? isActive, string? name, int pageNumber, int pageSize)
    {
        (pageNumber, pageSize) = Pagination.Normalize(pageNumber, pageSize);

        var query = _db.Imams.Include(i => i.Mosque).AsQueryable();

        if (mosqueId.HasValue)
            query = query.Where(i => i.MosqueId == mosqueId.Value);

        if (isActive.HasValue)
            query = query.Where(i => i.IsActive == isActive.Value);

        if (!string.IsNullOrWhiteSpace(name))
            query = query.Where(i => i.FirstName.Contains(name) || i.LastName.Contains(name));

        var total = await query.CountAsync();
        var items = await query
            .OrderBy(i => i.LastName)
            .Skip((pageNumber - 1) * pageSize)
            .Take(pageSize)
            .Select(i => ToResponse(i))
            .ToListAsync();

        return PagedResponse<ImamResponse>.Create(items, total, pageNumber, pageSize);
    }

    public async Task<ImamResponse?> GetByIdAsync(int id)
    {
        var imam = await _db.Imams.Include(i => i.Mosque).FirstOrDefaultAsync(i => i.Id == id);
        return imam == null ? null : ToResponse(imam);
    }

    public async Task<ImamResponse> CreateAsync(ImamRequest request)
    {
        var imam = new Imam
        {
            FirstName = request.FirstName,
            LastName = request.LastName,
            MosqueId = request.MosqueId,
            Phone = request.Phone,
            Email = request.Email,
            IsActive = request.IsActive
        };
        _db.Imams.Add(imam);
        await _db.SaveChangesAsync();
        await _db.Entry(imam).Reference(i => i.Mosque).LoadAsync();
        return ToResponse(imam);
    }

    public async Task<bool> UpdateAsync(int id, ImamRequest request)
    {
        var imam = await _db.Imams.FindAsync(id);
        if (imam == null) return false;

        imam.FirstName = request.FirstName;
        imam.LastName = request.LastName;
        imam.MosqueId = request.MosqueId;
        imam.Phone = request.Phone;
        imam.Email = request.Email;
        imam.IsActive = request.IsActive;

        await _db.SaveChangesAsync();
        return true;
    }

    public async Task<bool> DeleteAsync(int id)
    {
        var imam = await _db.Imams.FindAsync(id);
        if (imam == null) return false;
        _db.Imams.Remove(imam);
        await _db.SaveChangesAsync();
        return true;
    }

    private static ImamResponse ToResponse(Imam i) => new()
    {
        Id = i.Id,
        FirstName = i.FirstName,
        LastName = i.LastName,
        MosqueId = i.MosqueId,
        MosqueName = i.Mosque?.Name ?? string.Empty,
        Phone = i.Phone,
        Email = i.Email,
        IsActive = i.IsActive
    };
}

using MerhumAPI.Common;
using MerhumAPI.Data;
using MerhumAPI.DTOs.Condolence;
using MerhumAPI.Models;
using Microsoft.EntityFrameworkCore;

namespace MerhumAPI.Services;

public class CondolenceService : ICondolenceService
{
    private readonly ApplicationDbContext _db;

    public CondolenceService(ApplicationDbContext db) => _db = db;

    public async Task<PagedResponse<CondolenceResponse>> GetAllAsync(int? obituaryId, bool? isApproved, int pageNumber, int pageSize)
    {
        var query = _db.Condolences.AsQueryable();

        if (obituaryId.HasValue)
            query = query.Where(c => c.ObituaryId == obituaryId.Value);

        if (isApproved.HasValue)
            query = query.Where(c => c.IsApproved == isApproved.Value);

        var total = await query.CountAsync();
        var items = await query
            .OrderByDescending(c => c.CreatedAt)
            .Skip((pageNumber - 1) * pageSize)
            .Take(pageSize)
            .Select(c => ToResponse(c))
            .ToListAsync();

        return PagedResponse<CondolenceResponse>.Create(items, total, pageNumber, pageSize);
    }

    public async Task<CondolenceResponse?> GetByIdAsync(int id)
    {
        var c = await _db.Condolences.FindAsync(id);
        return c == null ? null : ToResponse(c);
    }

    public async Task<CondolenceResponse> CreateAsync(CondolenceRequest request, string? userId)
    {
        var obituary = await _db.Obituaries.FindAsync(request.ObituaryId)
            ?? throw new KeyNotFoundException("Obituary not found.");

        if (!obituary.IsActive || !obituary.IsPublic)
            throw new InvalidOperationException("Condolences cannot be submitted for this obituary.");

        var condolence = new Condolence
        {
            ObituaryId = request.ObituaryId,
            AuthorName = request.AuthorName,
            Text = request.Text,
            UserId = userId,
            IsApproved = false
        };

        _db.Condolences.Add(condolence);
        await _db.SaveChangesAsync();
        return ToResponse(condolence);
    }

    public async Task<bool> ApproveAsync(int id)
    {
        var condolence = await _db.Condolences.FindAsync(id);
        if (condolence == null) return false;
        condolence.IsApproved = true;
        await _db.SaveChangesAsync();
        return true;
    }

    public async Task<bool> DeleteAsync(int id)
    {
        var condolence = await _db.Condolences.FindAsync(id);
        if (condolence == null) return false;
        _db.Condolences.Remove(condolence);
        await _db.SaveChangesAsync();
        return true;
    }

    private static CondolenceResponse ToResponse(Condolence c) => new()
    {
        Id = c.Id,
        ObituaryId = c.ObituaryId,
        AuthorName = c.AuthorName,
        Text = c.Text,
        IsApproved = c.IsApproved,
        CreatedAt = c.CreatedAt
    };
}

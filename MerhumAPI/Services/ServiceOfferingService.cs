using MerhumAPI.Common;
using MerhumAPI.Data;
using MerhumAPI.DTOs.ServiceOffering;
using MerhumAPI.Models;
using Microsoft.EntityFrameworkCore;

namespace MerhumAPI.Services;

public class ServiceOfferingService : IServiceOfferingService
{
    private readonly ApplicationDbContext _db;

    public ServiceOfferingService(ApplicationDbContext db) => _db = db;

    public async Task<PagedResponse<ServiceOfferingResponse>> GetAllAsync(int? funeralHomeId, bool activeOnly, int pageNumber, int pageSize)
    {
        (pageNumber, pageSize) = Pagination.Normalize(pageNumber, pageSize);

        var query = _db.ServiceOfferings
            .Include(o => o.FuneralHome)
            .Include(o => o.ServiceType)
            .AsQueryable();

        if (funeralHomeId.HasValue)
            query = query.Where(o => o.FuneralHomeId == funeralHomeId.Value);

        if (activeOnly)
            query = query.Where(o => o.IsActive);

        var total = await query.CountAsync();
        var items = await query
            .OrderBy(o => o.FuneralHomeId).ThenBy(o => o.ServiceType.Name)
            .Skip((pageNumber - 1) * pageSize)
            .Take(pageSize)
            .Select(o => ToResponse(o))
            .ToListAsync();

        return PagedResponse<ServiceOfferingResponse>.Create(items, total, pageNumber, pageSize);
    }

    public async Task<ServiceOfferingResponse?> GetByIdAsync(int id)
    {
        var offering = await _db.ServiceOfferings
            .Include(o => o.FuneralHome)
            .Include(o => o.ServiceType)
            .FirstOrDefaultAsync(o => o.Id == id);

        return offering == null ? null : ToResponse(offering);
    }

    public async Task<ServiceOfferingResponse> CreateAsync(ServiceOfferingRequest request)
    {
        await EnsureNotDuplicateAsync(request, null);

        var offering = new ServiceOffering
        {
            FuneralHomeId = request.FuneralHomeId,
            ServiceTypeId = request.ServiceTypeId,
            Price = request.Price,
            Description = request.Description,
            IsActive = request.IsActive
        };

        _db.ServiceOfferings.Add(offering);
        await _db.SaveChangesAsync();

        return await GetByIdAsync(offering.Id) ?? ToResponse(offering);
    }

    public async Task<ServiceOfferingResponse?> UpdateAsync(int id, ServiceOfferingRequest request)
    {
        var offering = await _db.ServiceOfferings.FindAsync(id);
        if (offering == null) return null;

        await EnsureNotDuplicateAsync(request, id);

        offering.FuneralHomeId = request.FuneralHomeId;
        offering.ServiceTypeId = request.ServiceTypeId;
        offering.Price = request.Price;
        offering.Description = request.Description;
        offering.IsActive = request.IsActive;

        await _db.SaveChangesAsync();
        return await GetByIdAsync(id);
    }

    public async Task<bool> DeleteAsync(int id)
    {
        var offering = await _db.ServiceOfferings.FindAsync(id);
        if (offering == null) return false;

        var used = await _db.ServiceOrders.AnyAsync(s => s.ServiceOfferingId == id);
        if (used)
            throw new InvalidOperationException("Ponuda je vezana za narudžbe, umjesto brisanja je deaktivirajte.");

        _db.ServiceOfferings.Remove(offering);
        await _db.SaveChangesAsync();
        return true;
    }

    private async Task EnsureNotDuplicateAsync(ServiceOfferingRequest request, int? offeringId)
    {
        var duplicate = await _db.ServiceOfferings.AnyAsync(o => o.FuneralHomeId == request.FuneralHomeId
            && o.ServiceTypeId == request.ServiceTypeId
            && (offeringId == null || o.Id != offeringId));

        if (duplicate)
            throw new InvalidOperationException("Preduzeće već ima ponudu za tu uslugu.");
    }

    private static ServiceOfferingResponse ToResponse(ServiceOffering o) => new()
    {
        Id = o.Id,
        FuneralHomeId = o.FuneralHomeId,
        FuneralHomeName = o.FuneralHome != null ? o.FuneralHome.Name : string.Empty,
        ServiceTypeId = o.ServiceTypeId,
        ServiceTypeName = o.ServiceType != null ? o.ServiceType.Name : string.Empty,
        Price = o.Price,
        Description = o.Description,
        IsActive = o.IsActive
    };
}

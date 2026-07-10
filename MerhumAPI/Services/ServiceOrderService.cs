using MassTransit;
using MerhumAPI.Common;
using MerhumAPI.Data;
using MerhumAPI.DTOs.ServiceOrder;
using MerhumAPI.Messages;
using MerhumAPI.Models;
using Microsoft.EntityFrameworkCore;

namespace MerhumAPI.Services;

public class ServiceOrderService : IServiceOrderService
{
    private readonly ApplicationDbContext _db;
    private readonly IPublishEndpoint _publishEndpoint;

    public ServiceOrderService(ApplicationDbContext db, IPublishEndpoint publishEndpoint)
    {
        _db = db;
        _publishEndpoint = publishEndpoint;
    }

    public async Task<PagedResponse<ServiceOrderResponse>> GetAllAsync(int? deceasedId, string? status, int? funeralHomeId, DateTime? dateFrom, DateTime? dateTo, int pageNumber, int pageSize)
    {
        (pageNumber, pageSize) = Pagination.Normalize(pageNumber, pageSize);

        var query = _db.ServiceOrders
            .Include(s => s.Deceased)
            .Include(s => s.FuneralHome)
            .Include(s => s.ServiceType)
            .AsQueryable();

        if (deceasedId.HasValue)
            query = query.Where(s => s.DeceasedId == deceasedId.Value);

        if (!string.IsNullOrWhiteSpace(status))
            query = query.Where(s => s.Status == status);

        if (funeralHomeId.HasValue)
            query = query.Where(s => s.FuneralHomeId == funeralHomeId.Value);

        if (dateFrom.HasValue)
            query = query.Where(s => s.OrderedAt >= dateFrom.Value);

        if (dateTo.HasValue)
            query = query.Where(s => s.OrderedAt <= dateTo.Value);

        var total = await query.CountAsync();
        var items = await query
            .OrderByDescending(s => s.OrderedAt)
            .Skip((pageNumber - 1) * pageSize)
            .Take(pageSize)
            .Select(s => ToResponse(s))
            .ToListAsync();

        return PagedResponse<ServiceOrderResponse>.Create(items, total, pageNumber, pageSize);
    }

    public async Task<ServiceOrderResponse?> GetByIdAsync(int id)
    {
        var s = await _db.ServiceOrders
            .Include(x => x.Deceased)
            .Include(x => x.FuneralHome)
            .Include(x => x.ServiceType)
            .FirstOrDefaultAsync(x => x.Id == id);
        return s == null ? null : ToResponse(s);
    }

    public async Task<ServiceOrderResponse> CreateAsync(ServiceOrderRequest request)
    {
        var order = new ServiceOrder
        {
            DeceasedId = request.DeceasedId,
            FuneralHomeId = request.FuneralHomeId,
            ServiceTypeId = request.ServiceTypeId,
            Price = request.Price,
            Note = request.Note,
            Status = "Ordered"
        };

        _db.ServiceOrders.Add(order);
        await _db.SaveChangesAsync();

        await _db.Entry(order).Reference(s => s.Deceased).LoadAsync();
        await _db.Entry(order).Reference(s => s.FuneralHome).LoadAsync();
        await _db.Entry(order).Reference(s => s.ServiceType).LoadAsync();

        await _publishEndpoint.Publish(new ServiceOrderedMessage(
            order.Id,
            order.Deceased.Id,
            $"{order.Deceased.FirstName} {order.Deceased.LastName}",
            order.FuneralHome.Name,
            order.ServiceType.Name,
            order.Price,
            order.FuneralHome.Email ?? string.Empty,
            order.OrderedAt
        ));

        return ToResponse(order);
    }

    public async Task<ServiceOrderResponse?> UpdateAsync(int id, ServiceOrderUpdateRequest request)
    {
        var order = await _db.ServiceOrders.FindAsync(id);
        if (order == null) return null;

        order.DeceasedId = request.DeceasedId;
        order.FuneralHomeId = request.FuneralHomeId;
        order.ServiceTypeId = request.ServiceTypeId;
        order.Price = request.Price;
        order.Note = request.Note;

        if (!string.IsNullOrWhiteSpace(request.Status))
            order.Status = request.Status;

        if (request.Status == "Completed")
            order.CompletedAt = request.CompletedAt ?? DateTime.UtcNow;

        await _db.SaveChangesAsync();

        await _db.Entry(order).Reference(s => s.Deceased).LoadAsync();
        await _db.Entry(order).Reference(s => s.FuneralHome).LoadAsync();
        await _db.Entry(order).Reference(s => s.ServiceType).LoadAsync();

        return ToResponse(order);
    }

    public async Task<bool> UpdateStatusAsync(int id, string status, DateTime? completedAt)
    {
        var order = await _db.ServiceOrders.FindAsync(id);
        if (order == null) return false;

        order.Status = status;
        if (status == "Completed")
            order.CompletedAt = completedAt ?? DateTime.UtcNow;

        await _db.SaveChangesAsync();
        return true;
    }

    public async Task<bool> DeleteAsync(int id)
    {
        var order = await _db.ServiceOrders.FindAsync(id);
        if (order == null) return false;
        _db.ServiceOrders.Remove(order);
        await _db.SaveChangesAsync();
        return true;
    }

    private static ServiceOrderResponse ToResponse(ServiceOrder s) => new()
    {
        Id = s.Id,
        DeceasedId = s.DeceasedId,
        DeceasedFullName = s.Deceased != null ? $"{s.Deceased.FirstName} {s.Deceased.LastName}" : string.Empty,
        FuneralHomeId = s.FuneralHomeId,
        FuneralHomeName = s.FuneralHome?.Name ?? string.Empty,
        ServiceTypeId = s.ServiceTypeId,
        ServiceTypeName = s.ServiceType?.Name ?? string.Empty,
        Price = s.Price,
        Status = s.Status,
        Note = s.Note,
        OrderedAt = s.OrderedAt,
        CompletedAt = s.CompletedAt
    };
}

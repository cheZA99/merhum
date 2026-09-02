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
    private readonly INotificationService _notificationService;

    public ServiceOrderService(ApplicationDbContext db, IPublishEndpoint publishEndpoint, INotificationService notificationService)
    {
        _db = db;
        _publishEndpoint = publishEndpoint;
        _notificationService = notificationService;
    }

    public async Task<PagedResponse<ServiceOrderResponse>> GetAllAsync(int? deceasedId, ServiceOrderStatus? status, int? funeralHomeId, DateTime? dateFrom, DateTime? dateTo, int pageNumber, int pageSize, string? scopeToUserId)
    {
        (pageNumber, pageSize) = Pagination.Normalize(pageNumber, pageSize);

        var query = _db.ServiceOrders
            .Include(s => s.Deceased)
            .Include(s => s.FuneralHome)
            .Include(s => s.ServiceType)
            .AsQueryable();

        // a family sees the orders for its own deceased, a funeral home the ones placed with it
        if (scopeToUserId != null)
            query = query.Where(s => s.Deceased.UserId == scopeToUserId || s.FuneralHome.UserId == scopeToUserId);

        if (deceasedId.HasValue)
            query = query.Where(s => s.DeceasedId == deceasedId.Value);

        if (status.HasValue)
            query = query.Where(s => s.Status == status.Value);

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

    public async Task<ServiceOrderResponse?> GetByIdAsync(int id, string? scopeToUserId)
    {
        var s = await _db.ServiceOrders
            .Include(x => x.Deceased)
            .Include(x => x.FuneralHome)
            .Include(x => x.ServiceType)
            .FirstOrDefaultAsync(x => x.Id == id);

        if (s == null) return null;
        if (scopeToUserId != null && s.Deceased.UserId != scopeToUserId && s.FuneralHome.UserId != scopeToUserId) return null;

        return ToResponse(s);
    }

    public async Task<ServiceOrderResponse?> CreateAsync(ServiceOrderRequest request, string? scopeToUserId)
    {
        if (scopeToUserId != null)
        {
            var owner = await _db.Deceased.Where(d => d.Id == request.DeceasedId).Select(d => d.UserId).FirstOrDefaultAsync();
            if (owner != scopeToUserId) return null;
        }

        var order = new ServiceOrder
        {
            DeceasedId = request.DeceasedId,
            FuneralHomeId = request.FuneralHomeId,
            ServiceTypeId = request.ServiceTypeId,
            Price = request.Price,
            Note = request.Note,
            Status = ServiceOrderStatus.Ordered
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

        await _db.SaveChangesAsync();

        await _db.Entry(order).Reference(s => s.Deceased).LoadAsync();
        await _db.Entry(order).Reference(s => s.FuneralHome).LoadAsync();
        await _db.Entry(order).Reference(s => s.ServiceType).LoadAsync();

        return ToResponse(order);
    }

    public async Task<StatusChangeResult> UpdateStatusAsync(int id, ServiceOrderStatus status, string changedByUserId, string? reason, string? scopeToUserId)
    {
        var order = await _db.ServiceOrders
            .Include(o => o.Deceased)
            .Include(o => o.FuneralHome)
            .FirstOrDefaultAsync(o => o.Id == id);

        if (order == null) return StatusChangeResult.NotFound;

        if (scopeToUserId != null && order.Deceased.UserId != scopeToUserId && order.FuneralHome.UserId != scopeToUserId)
            return StatusChangeResult.Forbidden;

        if (!StatusTransitions.ServiceOrderAllows(order.Status, status))
            return StatusChangeResult.NotAllowed;

        order.Status = status;

        // the completion timestamp belongs to the completed state and to nothing else
        order.CompletedAt = status == ServiceOrderStatus.Completed ? DateTime.UtcNow : null;

        if (status == ServiceOrderStatus.Cancelled)
        {
            order.CancelledAt = DateTime.UtcNow;
            order.CancelledByUserId = changedByUserId;
            order.CancellationReason = reason;
        }

        await _db.SaveChangesAsync();

        await _notificationService.CreateForDeceasedAsync(order.DeceasedId, "Status usluge ažuriran", "Status vaše pogrebne usluge je promijenjen.");

        return StatusChangeResult.Ok;
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
        Status = s.Status.ToString(),
        Note = s.Note,
        OrderedAt = s.OrderedAt,
        CompletedAt = s.CompletedAt
    };
}

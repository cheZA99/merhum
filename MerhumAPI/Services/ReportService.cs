using MerhumAPI.Data;
using MerhumAPI.Models;
using MerhumAPI.Helpers;
using Microsoft.EntityFrameworkCore;

namespace MerhumAPI.Services;

public class ReportService : IReportService
{
    private readonly ApplicationDbContext _db;

    public ReportService(ApplicationDbContext db) => _db = db;

    public async Task<byte[]> GenerateDeceasedPdfAsync(int deceasedId)
    {
        var deceased = await _db.Deceased
            .Include(d => d.City).ThenInclude(c => c.Country)
            .Include(d => d.ProcedureStatus)
            .Include(d => d.Appointments).ThenInclude(a => a.Mosque)
            .Include(d => d.Appointments).ThenInclude(a => a.Cemetery)
            .Include(d => d.ServiceOrders).ThenInclude(s => s.ServiceType)
            .Include(d => d.ServiceOrders).ThenInclude(s => s.FuneralHome)
            .FirstOrDefaultAsync(d => d.Id == deceasedId)
            ?? throw new KeyNotFoundException($"Deceased with id {deceasedId} not found.");

        return PDFGenerator.GenerateDeceasedReport(deceased);
    }

    public async Task<byte[]> GenerateObituaryPdfAsync(string slug, string? viewerUserId)
    {
        var query = _db.Obituaries
            .Include(o => o.Deceased).ThenInclude(d => d.City).ThenInclude(c => c.Country)
            .Include(o => o.Condolences.Where(c => c.IsApproved))
            .Where(o => o.UniqueSlug == slug && o.IsActive);

        query = viewerUserId == null
            ? query.Where(o => o.IsPublic)
            : query.Where(o => o.IsPublic || o.Deceased.UserId == viewerUserId);

        var obituary = await query.FirstOrDefaultAsync()
            ?? throw new KeyNotFoundException($"Obituary with slug '{slug}' not found.");

        return PDFGenerator.GenerateObituaryDocument(obituary);
    }

    public async Task<object> GetDashboardStatsAsync()
    {
        var totalDeceased = await _db.Deceased.CountAsync();
        var totalObituaries = await _db.Obituaries.CountAsync();
        var totalCondolences = await _db.Condolences.CountAsync();
        var pendingCondolences = await _db.Condolences.CountAsync(c => !c.IsApproved);
        var totalAppointments = await _db.Appointments.CountAsync();
        var totalServiceOrders = await _db.ServiceOrders.CountAsync();
        var totalGraveSites = await _db.GraveSites.CountAsync();
        var availableGraveSites = await _db.GraveSites.CountAsync(g => g.Status == GraveSiteStatus.Available);

        return new
        {
            TotalDeceased = totalDeceased,
            TotalObituaries = totalObituaries,
            TotalCondolences = totalCondolences,
            PendingCondolences = pendingCondolences,
            TotalAppointments = totalAppointments,
            TotalServiceOrders = totalServiceOrders,
            TotalGraveSites = totalGraveSites,
            AvailableGraveSites = availableGraveSites
        };
    }

    public async Task<object> GetBurialReportAsync(int? year)
    {
        var targetYear = year ?? DateTime.UtcNow.Year;

        var byMonth = await _db.Appointments
            .Where(a => a.FuneralDateTime.Year == targetYear && a.Status == AppointmentStatus.Held)
            .GroupBy(a => new { a.FuneralDateTime.Month })
            .Select(g => new { Month = g.Key.Month, Count = g.Count() })
            .OrderBy(x => x.Month)
            .ToListAsync();

        var byCemetery = await _db.Appointments
            .Include(a => a.Cemetery)
            .Where(a => a.FuneralDateTime.Year == targetYear && a.Status == AppointmentStatus.Held)
            .GroupBy(a => new { a.CemeteryId, CemeteryName = a.Cemetery.Name })
            .Select(g => new { g.Key.CemeteryName, Count = g.Count() })
            .OrderByDescending(x => x.Count)
            .ToListAsync();

        return new { Year = targetYear, ByMonth = byMonth, ByCemetery = byCemetery };
    }

    public async Task<object> GetCemeteryCapacityReportAsync()
    {
        var cemeteries = await _db.Cemeteries
            .Include(c => c.City)
            .Select(c => new
            {
                c.Id,
                c.Name,
                CityName = c.City.Name,
                TotalSites = c.TotalPlaces,
                OccupiedSites = _db.GraveSites.Count(g => g.CemeteryId == c.Id && g.Status == GraveSiteStatus.Occupied),
                FreeSites = _db.GraveSites.Count(g => g.CemeteryId == c.Id && g.Status == GraveSiteStatus.Available),
                ReservedSites = _db.GraveSites.Count(g => g.CemeteryId == c.Id && g.Status == GraveSiteStatus.Reserved),
            })
            .ToListAsync();

        var result = cemeteries.Select(c => new
        {
            c.Id,
            c.Name,
            City = c.CityName,
            c.TotalSites,
            c.OccupiedSites,
            c.FreeSites,
            c.ReservedSites,
            FillPercentage = c.TotalSites > 0 ? Math.Round((double)c.OccupiedSites / c.TotalSites * 100, 1) : 0.0
        }).ToList();

        return new { Cemeteries = result };
    }

    public async Task<object> GetServicesReportAsync(int? year)
    {
        var targetYear = year ?? DateTime.UtcNow.Year;

        var ordered = _db.ServiceOrders.Where(s => s.OrderedAt.Year == targetYear);

        // revenue is counted separately from volume, because only a confirmed payment is income
        var paid = ordered.Where(s => _db.Payments.Any(p => p.ServiceOrderId == s.Id && p.Status == PaymentStatus.Completed));

        var countsByType = await ordered
            .GroupBy(s => new { s.ServiceTypeId, Name = s.ServiceType != null ? s.ServiceType.Name : "Nepoznato" })
            .Select(g => new { g.Key.ServiceTypeId, g.Key.Name, Count = g.Count() })
            .ToListAsync();

        var revenueByType = await paid
            .GroupBy(s => s.ServiceTypeId)
            .Select(g => new { ServiceTypeId = g.Key, Revenue = g.Sum(s => s.Price) })
            .ToListAsync();

        var byType = countsByType
            .Select(c => new
            {
                ServiceTypeName = c.Name,
                c.Count,
                TotalRevenue = revenueByType.FirstOrDefault(r => r.ServiceTypeId == c.ServiceTypeId)?.Revenue ?? 0m
            })
            .OrderByDescending(x => x.TotalRevenue)
            .ThenByDescending(x => x.Count)
            .ToList();

        var countsByHome = await ordered
            .GroupBy(s => new { s.FuneralHomeId, Name = s.FuneralHome != null ? s.FuneralHome.Name : "Nepoznato" })
            .Select(g => new { g.Key.FuneralHomeId, g.Key.Name, Count = g.Count() })
            .ToListAsync();

        var revenueByHome = await paid
            .GroupBy(s => s.FuneralHomeId)
            .Select(g => new { FuneralHomeId = g.Key, Revenue = g.Sum(s => s.Price) })
            .ToListAsync();

        var byFuneralHome = countsByHome
            .Select(c => new
            {
                FuneralHomeName = c.Name,
                c.Count,
                TotalRevenue = revenueByHome.FirstOrDefault(r => r.FuneralHomeId == c.FuneralHomeId)?.Revenue ?? 0m
            })
            .OrderByDescending(x => x.TotalRevenue)
            .ThenByDescending(x => x.Count)
            .ToList();

        return new { Year = targetYear, ByServiceType = byType, ByFuneralHome = byFuneralHome };
    }

    public async Task<object> GetObituariesStatsReportAsync()
    {
        var total = await _db.Obituaries.CountAsync();
        var active = await _db.Obituaries.CountAsync(o => o.IsActive);
        var publicCount = await _db.Obituaries.CountAsync(o => o.IsPublic);
        var totalViews = await _db.Obituaries.SumAsync(o => (long)o.ViewCount);
        var totalCondolences = await _db.Condolences.CountAsync();
        var approvedCondolences = await _db.Condolences.CountAsync(c => c.IsApproved);
        var pendingCondolences = totalCondolences - approvedCondolences;

        var topViewed = await _db.Obituaries
            .Include(o => o.Deceased)
            .OrderByDescending(o => o.ViewCount)
            .Take(10)
            .Select(o => new
            {
                o.Id,
                DeceasedFullName = $"{o.Deceased.FirstName} {o.Deceased.LastName}",
                o.UniqueSlug,
                o.ViewCount,
                CondolenceCount = o.Condolences.Count
            })
            .ToListAsync();

        return new
        {
            Total = total,
            Active = active,
            Inactive = total - active,
            Public = publicCount,
            Private = total - publicCount,
            TotalViews = totalViews,
            TotalCondolences = totalCondolences,
            ApprovedCondolences = approvedCondolences,
            PendingCondolences = pendingCondolences,
            TopViewed = topViewed
        };
    }

    public async Task<object> GetFinancialReportAsync(int? year)
    {
        var targetYear = year ?? DateTime.UtcNow.Year;

        var ordered = _db.ServiceOrders.Where(s => s.OrderedAt.Year == targetYear);

        // an order only turns into revenue once its payment is confirmed, but it still counts as volume
        var paidOrders = ordered
            .Where(s => _db.Payments.Any(p => p.ServiceOrderId == s.Id && p.Status == PaymentStatus.Completed));

        var countsByMonth = await ordered
            .GroupBy(s => s.OrderedAt.Month)
            .Select(g => new { Month = g.Key, OrderCount = g.Count() })
            .ToListAsync();

        var revenueByMonth = await paidOrders
            .GroupBy(s => s.OrderedAt.Month)
            .Select(g => new { Month = g.Key, Revenue = g.Sum(s => s.Price) })
            .ToListAsync();

        var byMonth = countsByMonth
            .Select(c => new
            {
                c.Month,
                c.OrderCount,
                TotalRevenue = revenueByMonth.FirstOrDefault(r => r.Month == c.Month)?.Revenue ?? 0m
            })
            .OrderBy(x => x.Month)
            .ToList();

        var totalRevenue = byMonth.Sum(x => x.TotalRevenue);
        var totalOrders = byMonth.Sum(x => x.OrderCount);

        var completedRevenue = await paidOrders
            .Where(s => s.Status == ServiceOrderStatus.Completed)
            .SumAsync(s => s.Price);

        return new
        {
            Year = targetYear,
            TotalRevenue = totalRevenue,
            TotalOrders = totalOrders,
            CompletedRevenue = completedRevenue,
            ByMonth = byMonth
        };
    }
}

using MerhumAPI.Data;
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

    public async Task<byte[]> GenerateObituaryPdfAsync(string slug)
    {
        var obituary = await _db.Obituaries
            .Include(o => o.Deceased).ThenInclude(d => d.City).ThenInclude(c => c.Country)
            .Include(o => o.Condolences.Where(c => c.IsApproved))
            .FirstOrDefaultAsync(o => o.UniqueSlug == slug)
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
        var availableGraveSites = await _db.GraveSites.CountAsync(g => g.Status == "Available");

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
            .Where(a => a.FuneralDateTime.Year == targetYear)
            .GroupBy(a => new { a.FuneralDateTime.Month })
            .Select(g => new { Month = g.Key.Month, Count = g.Count() })
            .OrderBy(x => x.Month)
            .ToListAsync();

        var byCemetery = await _db.Appointments
            .Include(a => a.Cemetery)
            .Where(a => a.FuneralDateTime.Year == targetYear)
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
                OccupiedSites = _db.GraveSites.Count(g => g.CemeteryId == c.Id && g.Status == "Occupied"),
                FreeSites = _db.GraveSites.Count(g => g.CemeteryId == c.Id && g.Status == "Available"),
                ReservedSites = _db.GraveSites.Count(g => g.CemeteryId == c.Id && g.Status == "Reserved"),
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

        var byType = await _db.ServiceOrders
            .Include(s => s.ServiceType)
            .Where(s => s.OrderedAt.Year == targetYear)
            .GroupBy(s => new { s.ServiceTypeId, ServiceTypeName = s.ServiceType != null ? s.ServiceType.Name : "Nepoznato" })
            .Select(g => new
            {
                g.Key.ServiceTypeName,
                Count = g.Count(),
                TotalRevenue = g.Sum(s => s.Price)
            })
            .OrderByDescending(x => x.TotalRevenue)
            .ToListAsync();

        var byFuneralHome = await _db.ServiceOrders
            .Include(s => s.FuneralHome)
            .Where(s => s.OrderedAt.Year == targetYear)
            .GroupBy(s => new { s.FuneralHomeId, FuneralHomeName = s.FuneralHome != null ? s.FuneralHome.Name : "Nepoznato" })
            .Select(g => new
            {
                g.Key.FuneralHomeName,
                Count = g.Count(),
                TotalRevenue = g.Sum(s => s.Price)
            })
            .OrderByDescending(x => x.TotalRevenue)
            .ToListAsync();

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

        var byMonth = await _db.ServiceOrders
            .Where(s => s.OrderedAt.Year == targetYear)
            .GroupBy(s => s.OrderedAt.Month)
            .Select(g => new
            {
                Month = g.Key,
                OrderCount = g.Count(),
                TotalRevenue = g.Sum(s => s.Price)
            })
            .OrderBy(x => x.Month)
            .ToListAsync();

        var totalRevenue = byMonth.Sum(x => x.TotalRevenue);
        var totalOrders = byMonth.Sum(x => x.OrderCount);

        var completedRevenue = await _db.ServiceOrders
            .Where(s => s.OrderedAt.Year == targetYear && s.Status == "Completed")
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

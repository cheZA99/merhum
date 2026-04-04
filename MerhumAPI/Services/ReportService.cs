using MerhumAPI.Data;
using MerhumAPI.Helpers;
using Microsoft.EntityFrameworkCore;

namespace MerhumAPI.Services;

public class ReportService : IReportService
{
    private readonly ApplicationDbContext _db;

    public ReportService(ApplicationDbContext db)
    {
        _db = db;
    }

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
}

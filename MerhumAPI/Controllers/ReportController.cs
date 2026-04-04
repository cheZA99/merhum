using MerhumAPI.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace MerhumAPI.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize(Policy = "DesktopAccess")]
public class ReportController : ControllerBase
{
    private readonly IReportService _reportService;
    public ReportController(IReportService reportService) => _reportService = reportService;

    /// <summary>Download PDF report for a deceased person</summary>
    [HttpGet("deceased/{id:int}/pdf")]
    public async Task<IActionResult> DeceasedPdf(int id)
    {
        var bytes = await _reportService.GenerateDeceasedPdfAsync(id);
        return File(bytes, "application/pdf", $"deceased-{id}.pdf");
    }

    /// <summary>Download PDF obituary document by slug</summary>
    [HttpGet("obituary/{slug}/pdf")]
    [AllowAnonymous]
    public async Task<IActionResult> ObituaryPdf(string slug)
    {
        var bytes = await _reportService.GenerateObituaryPdfAsync(slug);
        return File(bytes, "application/pdf", $"obituary-{slug}.pdf");
    }

    /// <summary>Get dashboard statistics</summary>
    [HttpGet("dashboard")]
    public async Task<IActionResult> Dashboard()
    {
        var stats = await _reportService.GetDashboardStatsAsync();
        return Ok(stats);
    }
}

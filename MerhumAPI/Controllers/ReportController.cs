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

    [HttpGet("deceased/{id:int}/pdf")]
    public async Task<IActionResult> DeceasedPdf(int id)
    {
        var bytes = await _reportService.GenerateDeceasedPdfAsync(id);
        return File(bytes, "application/pdf", $"deceased-{id}.pdf");
    }

    [HttpGet("obituary/{slug}/pdf")]
    [AllowAnonymous]
    public async Task<IActionResult> ObituaryPdf(string slug)
    {
        var bytes = await _reportService.GenerateObituaryPdfAsync(slug);
        return File(bytes, "application/pdf", $"obituary-{slug}.pdf");
    }

    [HttpGet("dashboard")]
    public async Task<IActionResult> Dashboard()
    {
        var stats = await _reportService.GetDashboardStatsAsync();
        return Ok(stats);
    }

    [HttpGet("burial")]
    public async Task<IActionResult> Burial([FromQuery] int? year)
    {
        var data = await _reportService.GetBurialReportAsync(year);
        return Ok(data);
    }

    [HttpGet("cemetery-capacity")]
    public async Task<IActionResult> CemeteryCapacity()
    {
        var data = await _reportService.GetCemeteryCapacityReportAsync();
        return Ok(data);
    }

    [HttpGet("services")]
    public async Task<IActionResult> Services([FromQuery] int? year)
    {
        var data = await _reportService.GetServicesReportAsync(year);
        return Ok(data);
    }

    [HttpGet("obituaries-stats")]
    public async Task<IActionResult> ObituariesStats()
    {
        var data = await _reportService.GetObituariesStatsReportAsync();
        return Ok(data);
    }

    [HttpGet("financial")]
    public async Task<IActionResult> Financial([FromQuery] int? year)
    {
        var data = await _reportService.GetFinancialReportAsync(year);
        return Ok(data);
    }
}

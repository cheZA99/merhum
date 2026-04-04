using MerhumAPI.Data;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace MerhumAPI.Controllers;

[ApiController]
[Route("api/[controller]")]
public class ReferenceDataController : ControllerBase
{
    private readonly ApplicationDbContext _db;
    public ReferenceDataController(ApplicationDbContext db) => _db = db;

    [HttpGet("countries")]
    public async Task<IActionResult> GetCountries()
        => Ok(await _db.Countries.Select(c => new { c.Id, c.Name, c.Code }).ToListAsync());

    [HttpGet("cities")]
    public async Task<IActionResult> GetCities([FromQuery] int? countryId)
    {
        var query = _db.Cities.Include(c => c.Country).AsQueryable();
        if (countryId.HasValue) query = query.Where(c => c.CountryId == countryId.Value);
        return Ok(await query.Select(c => new { c.Id, c.Name, c.PostalCode, c.CountryId, CountryName = c.Country.Name }).ToListAsync());
    }

    [HttpGet("service-types")]
    public async Task<IActionResult> GetServiceTypes()
        => Ok(await _db.ServiceTypes.Select(s => new { s.Id, s.Name, s.Description }).ToListAsync());

    [HttpGet("procedure-statuses")]
    public async Task<IActionResult> GetProcedureStatuses()
        => Ok(await _db.ProcedureStatuses.OrderBy(s => s.SortOrder).Select(s => new { s.Id, s.Name, s.Description, s.SortOrder }).ToListAsync());

    [HttpGet("cemetery-sections")]
    public async Task<IActionResult> GetCemeterySections([FromQuery] int? cemeteryId)
    {
        var query = _db.CemeterySections.AsQueryable();
        if (cemeteryId.HasValue) query = query.Where(s => s.CemeteryId == cemeteryId.Value);
        return Ok(await query.Select(s => new { s.Id, s.Name, s.CemeteryId }).ToListAsync());
    }
}

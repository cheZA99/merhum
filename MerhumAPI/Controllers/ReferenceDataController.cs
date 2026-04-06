using MerhumAPI.Data;
using MerhumAPI.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace MerhumAPI.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class ReferenceDataController :ControllerBase
{
	private readonly ApplicationDbContext _db;
	public ReferenceDataController(ApplicationDbContext db) => _db = db;

	[HttpGet("countries")]
	public async Task<IActionResult> GetCountries()
	    => Ok(await _db.Countries.Select(c => new { c.Id, c.Name, c.Code }).ToListAsync());

	[HttpPost("countries")]
	[Authorize(Policy = "AdminOnly")]
	public async Task<IActionResult> CreateCountry([FromBody] CountryRequest req)
	{
		var country = new Country { Name = req.Name, Code = req.Code.ToUpper() };
		_db.Countries.Add(country);
		await _db.SaveChangesAsync();
		return Created("", new { country.Id, country.Name, country.Code });
	}

	[HttpPut("countries/{id:int}")]
	[Authorize(Policy = "AdminOnly")]
	public async Task<IActionResult> UpdateCountry(int id, [FromBody] CountryRequest req)
	{
		var country = await _db.Countries.FindAsync(id);
		if (country == null)
			return NotFound();
		country.Name = req.Name;
		country.Code = req.Code.ToUpper();
		await _db.SaveChangesAsync();
		return NoContent();
	}

	[HttpDelete("countries/{id:int}")]
	[Authorize(Policy = "AdminOnly")]
	public async Task<IActionResult> DeleteCountry(int id)
	{
		var country = await _db.Countries.FindAsync(id);
		if (country == null)
			return NotFound();
		_db.Countries.Remove(country);
		await _db.SaveChangesAsync();
		return NoContent();
	}


	[HttpGet("cities")]
	public async Task<IActionResult> GetCities([FromQuery] int? countryId)
	{
		var query = _db.Cities.Include(c => c.Country).AsQueryable();
		if (countryId.HasValue)
			query = query.Where(c => c.CountryId == countryId.Value);
		return Ok(await query.Select(c => new { c.Id, c.Name, c.PostalCode, c.CountryId, CountryName = c.Country.Name }).ToListAsync());
	}

	[HttpPost("cities")]
	[Authorize(Policy = "AdminOnly")]
	public async Task<IActionResult> CreateCity([FromBody] CityRequest req)
	{
		var city = new City { Name = req.Name, PostalCode = req.PostalCode, CountryId = req.CountryId };
		_db.Cities.Add(city);
		await _db.SaveChangesAsync();
		var country = await _db.Countries.FindAsync(req.CountryId);
		return Created("", new { city.Id, city.Name, city.PostalCode, city.CountryId, CountryName = country?.Name ?? "" });
	}

	[HttpPut("cities/{id:int}")]
	[Authorize(Policy = "AdminOnly")]
	public async Task<IActionResult> UpdateCity(int id, [FromBody] CityRequest req)
	{
		var city = await _db.Cities.FindAsync(id);
		if (city == null)
			return NotFound();
		city.Name = req.Name;
		city.PostalCode = req.PostalCode;
		city.CountryId = req.CountryId;
		await _db.SaveChangesAsync();
		return NoContent();
	}

	[HttpDelete("cities/{id:int}")]
	[Authorize(Policy = "AdminOnly")]
	public async Task<IActionResult> DeleteCity(int id)
	{
		var city = await _db.Cities.FindAsync(id);
		if (city == null)
			return NotFound();
		_db.Cities.Remove(city);
		await _db.SaveChangesAsync();
		return NoContent();
	}


	[HttpGet("service-types")]
	public async Task<IActionResult> GetServiceTypes()
	    => Ok(await _db.ServiceTypes.Select(s => new { s.Id, s.Name, s.Description }).ToListAsync());

	[HttpPost("service-types")]
	[Authorize(Policy = "AdminOnly")]
	public async Task<IActionResult> CreateServiceType([FromBody] ServiceTypeRequest req)
	{
		var st = new ServiceType { Name = req.Name, Description = req.Description };
		_db.ServiceTypes.Add(st);
		await _db.SaveChangesAsync();
		return Created("", new { st.Id, st.Name, st.Description });
	}

	[HttpPut("service-types/{id:int}")]
	[Authorize(Policy = "AdminOnly")]
	public async Task<IActionResult> UpdateServiceType(int id, [FromBody] ServiceTypeRequest req)
	{
		var st = await _db.ServiceTypes.FindAsync(id);
		if (st == null)
			return NotFound();
		st.Name = req.Name;
		st.Description = req.Description;
		await _db.SaveChangesAsync();
		return NoContent();
	}

	[HttpDelete("service-types/{id:int}")]
	[Authorize(Policy = "AdminOnly")]
	public async Task<IActionResult> DeleteServiceType(int id)
	{
		var st = await _db.ServiceTypes.FindAsync(id);
		if (st == null)
			return NotFound();
		_db.ServiceTypes.Remove(st);
		await _db.SaveChangesAsync();
		return NoContent();
	}


	[HttpGet("procedure-statuses")]
	public async Task<IActionResult> GetProcedureStatuses()
	    => Ok(await _db.ProcedureStatuses.OrderBy(s => s.SortOrder).Select(s => new { s.Id, s.Name, s.Description, s.SortOrder }).ToListAsync());

	[HttpGet("cemetery-sections")]
	public async Task<IActionResult> GetCemeterySections([FromQuery] int? cemeteryId)
	{
		var query = _db.CemeterySections.AsQueryable();
		if (cemeteryId.HasValue)
			query = query.Where(s => s.CemeteryId == cemeteryId.Value);
		return Ok(await query.Select(s => new { s.Id, s.Name, s.CemeteryId }).ToListAsync());
	}

	[HttpPost("cemetery-sections")]
	[Authorize(Policy = "AdminOnly")]
	public async Task<IActionResult> CreateSection([FromBody] SectionRequest req)
	{
		var section = new CemeterySection { Name = req.Name, CemeteryId = req.CemeteryId };
		_db.CemeterySections.Add(section);
		await _db.SaveChangesAsync();
		return Created("", new { section.Id, section.Name, section.CemeteryId });
	}

	[HttpPut("cemetery-sections/{id:int}")]
	[Authorize(Policy = "AdminOnly")]
	public async Task<IActionResult> UpdateSection(int id, [FromBody] SectionRequest req)
	{
		var section = await _db.CemeterySections.FindAsync(id);
		if (section == null)
			return NotFound();
		section.Name = req.Name;
		section.CemeteryId = req.CemeteryId;
		await _db.SaveChangesAsync();
		return NoContent();
	}

	[HttpDelete("cemetery-sections/{id:int}")]
	[Authorize(Policy = "AdminOnly")]
	public async Task<IActionResult> DeleteSection(int id)
	{
		var section = await _db.CemeterySections.FindAsync(id);
		if (section == null)
			return NotFound();
		_db.CemeterySections.Remove(section);
		await _db.SaveChangesAsync();
		return NoContent();
	}
}

public record CountryRequest(string Name, string Code);
public record CityRequest(string Name, string? PostalCode, int CountryId);
public record ServiceTypeRequest(string Name, string? Description);
public record SectionRequest(string Name, int CemeteryId);

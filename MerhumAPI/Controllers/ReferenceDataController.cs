using MerhumAPI.DTOs.ReferenceData;
using MerhumAPI.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace MerhumAPI.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class ReferenceDataController : ControllerBase
{
	private readonly IReferenceDataService _referenceDataService;
	public ReferenceDataController(IReferenceDataService referenceDataService) => _referenceDataService = referenceDataService;

	[HttpGet("countries")]
	public async Task<IActionResult> GetCountries([FromQuery] int pageNumber = 1, [FromQuery] int pageSize = 20)
	    => Ok(await _referenceDataService.GetCountriesAsync(pageNumber, pageSize));

	[HttpPost("countries")]
	[Authorize(Policy = "AdminOnly")]
	public async Task<IActionResult> CreateCountry([FromBody] CountryRequest req)
	{
		var country = await _referenceDataService.CreateCountryAsync(req);
		return Created("", country);
	}

	[HttpPut("countries/{id:int}")]
	[Authorize(Policy = "AdminOnly")]
	public async Task<IActionResult> UpdateCountry(int id, [FromBody] CountryRequest req)
	{
		var updated = await _referenceDataService.UpdateCountryAsync(id, req);
		if (!updated) return NotFound();
		return NoContent();
	}

	[HttpDelete("countries/{id:int}")]
	[Authorize(Policy = "AdminOnly")]
	public async Task<IActionResult> DeleteCountry(int id)
	{
		var deleted = await _referenceDataService.DeleteCountryAsync(id);
		if (!deleted) return NotFound();
		return NoContent();
	}


	[HttpGet("cities")]
	public async Task<IActionResult> GetCities([FromQuery] int? countryId, [FromQuery] int pageNumber = 1, [FromQuery] int pageSize = 20)
	    => Ok(await _referenceDataService.GetCitiesAsync(countryId, pageNumber, pageSize));

	[HttpPost("cities")]
	[Authorize(Policy = "AdminOnly")]
	public async Task<IActionResult> CreateCity([FromBody] CityRequest req)
	{
		var city = await _referenceDataService.CreateCityAsync(req);
		return Created("", city);
	}

	[HttpPut("cities/{id:int}")]
	[Authorize(Policy = "AdminOnly")]
	public async Task<IActionResult> UpdateCity(int id, [FromBody] CityRequest req)
	{
		var updated = await _referenceDataService.UpdateCityAsync(id, req);
		if (!updated) return NotFound();
		return NoContent();
	}

	[HttpDelete("cities/{id:int}")]
	[Authorize(Policy = "AdminOnly")]
	public async Task<IActionResult> DeleteCity(int id)
	{
		var deleted = await _referenceDataService.DeleteCityAsync(id);
		if (!deleted) return NotFound();
		return NoContent();
	}


	[HttpGet("service-types")]
	public async Task<IActionResult> GetServiceTypes([FromQuery] int pageNumber = 1, [FromQuery] int pageSize = 20)
	    => Ok(await _referenceDataService.GetServiceTypesAsync(pageNumber, pageSize));

	[HttpPost("service-types")]
	[Authorize(Policy = "AdminOnly")]
	public async Task<IActionResult> CreateServiceType([FromBody] ServiceTypeRequest req)
	{
		var st = await _referenceDataService.CreateServiceTypeAsync(req);
		return Created("", st);
	}

	[HttpPut("service-types/{id:int}")]
	[Authorize(Policy = "AdminOnly")]
	public async Task<IActionResult> UpdateServiceType(int id, [FromBody] ServiceTypeRequest req)
	{
		var updated = await _referenceDataService.UpdateServiceTypeAsync(id, req);
		if (!updated) return NotFound();
		return NoContent();
	}

	[HttpDelete("service-types/{id:int}")]
	[Authorize(Policy = "AdminOnly")]
	public async Task<IActionResult> DeleteServiceType(int id)
	{
		var deleted = await _referenceDataService.DeleteServiceTypeAsync(id);
		if (!deleted) return NotFound();
		return NoContent();
	}


	[HttpGet("procedure-statuses")]
	public async Task<IActionResult> GetProcedureStatuses([FromQuery] int pageNumber = 1, [FromQuery] int pageSize = 20)
	    => Ok(await _referenceDataService.GetProcedureStatusesAsync(pageNumber, pageSize));

	[HttpGet("muftiates")]
	public async Task<IActionResult> GetMuftiates([FromQuery] int pageNumber = 1, [FromQuery] int pageSize = 50)
	    => Ok(await _referenceDataService.GetMuftiatesAsync(pageNumber, pageSize));

	[HttpGet("majlises")]
	public async Task<IActionResult> GetMajlises([FromQuery] int? muftiateId, [FromQuery] int pageNumber = 1, [FromQuery] int pageSize = 100)
	    => Ok(await _referenceDataService.GetMajlisesAsync(muftiateId, pageNumber, pageSize));

	[HttpGet("cemetery-sections")]
	public async Task<IActionResult> GetCemeterySections([FromQuery] int? cemeteryId, [FromQuery] int pageNumber = 1, [FromQuery] int pageSize = 20)
	    => Ok(await _referenceDataService.GetCemeterySectionsAsync(cemeteryId, pageNumber, pageSize));

	[HttpPost("cemetery-sections")]
	[Authorize(Policy = "AdminOnly")]
	public async Task<IActionResult> CreateSection([FromBody] SectionRequest req)
	{
		var section = await _referenceDataService.CreateSectionAsync(req);
		return Created("", section);
	}

	[HttpPut("cemetery-sections/{id:int}")]
	[Authorize(Policy = "AdminOnly")]
	public async Task<IActionResult> UpdateSection(int id, [FromBody] SectionRequest req)
	{
		var updated = await _referenceDataService.UpdateSectionAsync(id, req);
		if (!updated) return NotFound();
		return NoContent();
	}

	[HttpDelete("cemetery-sections/{id:int}")]
	[Authorize(Policy = "AdminOnly")]
	public async Task<IActionResult> DeleteSection(int id)
	{
		var deleted = await _referenceDataService.DeleteSectionAsync(id);
		if (!deleted) return NotFound();
		return NoContent();
	}
}

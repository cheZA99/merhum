using MassTransit;
using MerhumAPI.Data;
using MerhumAPI.DTOs.Deceased;
using MerhumAPI.Messages;
using MerhumAPI.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;

namespace MerhumAPI.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class DeceasedController : ControllerBase
{
    private readonly ApplicationDbContext _db;
    private readonly IPublishEndpoint _publishEndpoint;

    public DeceasedController(ApplicationDbContext db, IPublishEndpoint publishEndpoint)
    {
        _db = db;
        _publishEndpoint = publishEndpoint;
    }

    /// <summary>Get all deceased with optional filtering</summary>
    [HttpGet]
    [Authorize(Policy = "DesktopAccess")]
    public async Task<ActionResult<IEnumerable<DeceasedResponse>>> GetAll(
        [FromQuery] string? search,
        [FromQuery] int? statusId,
        [FromQuery] int? cityId,
        [FromQuery] bool withoutGraveSite = false)
    {
        var query = _db.Deceased
            .Include(d => d.City).ThenInclude(c => c.Country)
            .Include(d => d.ProcedureStatus)
            .Include(d => d.Obituary)
            .Include(d => d.User)
            .AsQueryable();

        if (!string.IsNullOrWhiteSpace(search))
            query = query.Where(d => (d.FirstName + " " + d.LastName).Contains(search));

        if (statusId.HasValue)
            query = query.Where(d => d.ProcedureStatusId == statusId.Value);

        if (cityId.HasValue)
            query = query.Where(d => d.CityId == cityId.Value);

        if (withoutGraveSite)
            query = query.Where(d => !_db.GraveSites.Any(g => g.DeceasedId == d.Id));

        var result = await query.OrderByDescending(d => d.CreatedAt).Select(d => new DeceasedResponse
        {
            Id = d.Id,
            FirstName = d.FirstName,
            LastName = d.LastName,
            DateOfBirth = d.DateOfBirth,
            DateOfDeath = d.DateOfDeath,
            PlaceOfDeath = d.PlaceOfDeath,
            PhotoUrl = d.PhotoUrl,
            ContactPersonName = d.ContactPersonName,
            ContactPersonPhone = d.ContactPersonPhone,
            ContactPersonEmail = d.ContactPersonEmail,
            CityName = d.City.Name,
            CountryName = d.City.Country.Name,
            ProcedureStatusId = d.ProcedureStatusId,
            ProcedureStatusName = d.ProcedureStatus.Name,
            CreatedAt = d.CreatedAt,
            ObituarySlug = d.Obituary != null ? d.Obituary.UniqueSlug : null,
            CityId = d.CityId,
            CreatedByUsername = d.User.UserName ?? ""
        }).ToListAsync();

        return Ok(result);
    }

    /// <summary>Get single deceased by id</summary>
    [HttpGet("{id:int}")]
    [Authorize(Policy = "MobileAccess")]
    public async Task<ActionResult<DeceasedResponse>> GetById(int id)
    {
        var d = await _db.Deceased
            .Include(x => x.City).ThenInclude(c => c.Country)
            .Include(x => x.ProcedureStatus)
            .Include(x => x.Obituary)
            .Include(x => x.User)
            .FirstOrDefaultAsync(x => x.Id == id);

        if (d == null) return NotFound();

        return Ok(new DeceasedResponse
        {
            Id = d.Id,
            FirstName = d.FirstName,
            LastName = d.LastName,
            DateOfBirth = d.DateOfBirth,
            DateOfDeath = d.DateOfDeath,
            PlaceOfDeath = d.PlaceOfDeath,
            PhotoUrl = d.PhotoUrl,
            ContactPersonName = d.ContactPersonName,
            ContactPersonPhone = d.ContactPersonPhone,
            ContactPersonEmail = d.ContactPersonEmail,
            CityName = d.City.Name,
            CountryName = d.City.Country.Name,
            ProcedureStatusId = d.ProcedureStatusId,
            ProcedureStatusName = d.ProcedureStatus.Name,
            CreatedAt = d.CreatedAt,
            ObituarySlug = d.Obituary?.UniqueSlug,
            CityId = d.CityId,
            CreatedByUsername = d.User.UserName ?? ""
        });
    }

    /// <summary>Register a new deceased person</summary>
    [HttpPost]
    [Authorize(Policy = "DesktopAccess")]
    public async Task<ActionResult<DeceasedResponse>> Create([FromBody] DeceasedRequest request)
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier)
                  ?? User.FindFirstValue("sub")
                  ?? throw new UnauthorizedAccessException();

        var deceased = new Deceased
        {
            FirstName = request.FirstName,
            LastName = request.LastName,
            DateOfBirth = request.DateOfBirth,
            DateOfDeath = request.DateOfDeath,
            PlaceOfDeath = request.PlaceOfDeath,
            PhotoUrl = request.PhotoUrl,
            ContactPersonName = request.ContactPersonName,
            ContactPersonPhone = request.ContactPersonPhone,
            ContactPersonEmail = request.ContactPersonEmail,
            CityId = request.CityId,
            ProcedureStatusId = request.ProcedureStatusId,
            UserId = userId
        };

        _db.Deceased.Add(deceased);
        await _db.SaveChangesAsync();

        await _publishEndpoint.Publish(new FuneralRegisteredMessage(
            deceased.Id,
            $"{deceased.FirstName} {deceased.LastName}",
            deceased.ContactPersonEmail ?? string.Empty,
            deceased.ContactPersonName,
            deceased.ContactPersonPhone,
            deceased.CreatedAt
        ));

        return CreatedAtAction(nameof(GetById), new { id = deceased.Id }, new DeceasedResponse
        {
            Id = deceased.Id,
            FirstName = deceased.FirstName,
            LastName = deceased.LastName,
            DateOfBirth = deceased.DateOfBirth,
            DateOfDeath = deceased.DateOfDeath,
            PlaceOfDeath = deceased.PlaceOfDeath,
            PhotoUrl = deceased.PhotoUrl,
            ContactPersonName = deceased.ContactPersonName,
            ContactPersonPhone = deceased.ContactPersonPhone,
            ContactPersonEmail = deceased.ContactPersonEmail,
            CityName = string.Empty,
            CountryName = string.Empty,
            ProcedureStatusId = deceased.ProcedureStatusId,
            ProcedureStatusName = string.Empty,
            CreatedAt = deceased.CreatedAt
        });
    }

    /// <summary>Update deceased record</summary>
    [HttpPut("{id:int}")]
    [Authorize(Policy = "DesktopAccess")]
    public async Task<IActionResult> Update(int id, [FromBody] DeceasedRequest request)
    {
        var deceased = await _db.Deceased.FindAsync(id);
        if (deceased == null) return NotFound();

        deceased.FirstName = request.FirstName;
        deceased.LastName = request.LastName;
        deceased.DateOfBirth = request.DateOfBirth;
        deceased.DateOfDeath = request.DateOfDeath;
        deceased.PlaceOfDeath = request.PlaceOfDeath;
        deceased.PhotoUrl = request.PhotoUrl;
        deceased.ContactPersonName = request.ContactPersonName;
        deceased.ContactPersonPhone = request.ContactPersonPhone;
        deceased.ContactPersonEmail = request.ContactPersonEmail;
        deceased.CityId = request.CityId;
        deceased.ProcedureStatusId = request.ProcedureStatusId;

        await _db.SaveChangesAsync();
        return NoContent();
    }

    /// <summary>Update procedure status</summary>
    [HttpPatch("{id:int}/status")]
    [Authorize(Policy = "DesktopAccess")]
    public async Task<IActionResult> UpdateStatus(int id, [FromBody] UpdateStatusRequest request)
    {
        var deceased = await _db.Deceased.FindAsync(id);
        if (deceased == null) return NotFound();

        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier)
                  ?? User.FindFirstValue("sub")
                  ?? throw new UnauthorizedAccessException();

        deceased.ProcedureStatusId = request.StatusId;

        _db.StatusHistories.Add(new StatusHistory
        {
            DeceasedId = id,
            StatusId = request.StatusId,
            Note = request.Note,
            ChangedByUserId = userId
        });

        await _db.SaveChangesAsync();
        return NoContent();
    }

    /// <summary>Upload photo for deceased</summary>
    [HttpPost("{id:int}/photo")]
    [Authorize(Policy = "DesktopAccess")]
    public async Task<IActionResult> UploadPhoto(int id, IFormFile file)
    {
        var deceased = await _db.Deceased.FindAsync(id);
        if (deceased == null) return NotFound();

        if (file == null || file.Length == 0)
            return BadRequest(new { message = "No file provided." });

        var ext = Path.GetExtension(file.FileName).ToLowerInvariant();
        if (ext is not (".jpg" or ".jpeg" or ".png" or ".webp"))
            return BadRequest(new { message = "Unsupported file type." });

        var folder = Path.Combine("wwwroot", "uploads", "photos");
        Directory.CreateDirectory(folder);

        var fileName = $"deceased-{id}-{Guid.NewGuid():N}{ext}";
        var filePath = Path.Combine(folder, fileName);

        using (var stream = new FileStream(filePath, FileMode.Create))
            await file.CopyToAsync(stream);

        deceased.PhotoUrl = $"/uploads/photos/{fileName}";
        await _db.SaveChangesAsync();

        return Ok(new { photoUrl = deceased.PhotoUrl });
    }

    /// <summary>Delete deceased record</summary>
    [HttpDelete("{id:int}")]
    [Authorize(Policy = "AdminOnly")]
    public async Task<IActionResult> Delete(int id)
    {
        var deceased = await _db.Deceased.FindAsync(id);
        if (deceased == null) return NotFound();

        _db.Deceased.Remove(deceased);
        await _db.SaveChangesAsync();
        return NoContent();
    }

    [HttpGet("{id:int}/status-history")]
    [Authorize(Policy = "DesktopAccess")]
    public async Task<IActionResult> GetStatusHistory(int id)
    {
        var history = await _db.StatusHistories
            .Include(h => h.ProcedureStatus)
            .Include(h => h.ChangedByUser)
            .Where(h => h.DeceasedId == id)
            .OrderBy(h => h.ChangedAt)
            .Select(h => new {
                h.Id,
                h.DeceasedId,
                h.StatusId,
                StatusName = h.ProcedureStatus.Name,
                h.Note,
                h.ChangedAt,
                ChangedByUsername = h.ChangedByUser.UserName ?? ""
            })
            .ToListAsync();
        return Ok(history);
    }
}

public class UpdateStatusRequest
{
    public int StatusId { get; set; }
    public string? Note { get; set; }
}

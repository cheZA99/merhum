using MerhumAPI.Common;
using MerhumAPI.Data;
using MerhumAPI.DTOs.MachineLearning;
using MerhumAPI.Services.MachineLearning;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace MerhumAPI.Controllers;

[ApiController]
[Route("api/predikcije")]
[Authorize(Policy = "DesktopAccess")]
public class PredictionController : ControllerBase
{
    private readonly ICemeteryPredictionService _predictionService;
    private readonly ApplicationDbContext _db;

    public PredictionController(ICemeteryPredictionService predictionService, ApplicationDbContext db)
    {
        _predictionService = predictionService;
        _db = db;
    }

    [HttpPost("treniraj")]
    public async Task<ActionResult<ApiResponse<object>>> Train()
    {
        await _predictionService.TrainModelAsync();
        return Ok(ApiResponse<object>.Ok(new { }, "Model je uspješno treniran."));
    }

    [HttpGet("groblje/{cemeteryId:int}")]
    public async Task<ActionResult<ApiResponse<CemeteryPredictionResultDto>>> GetForCemetery(int cemeteryId)
    {
        var result = await _predictionService.PredictAsync(cemeteryId);
        if (result == null)
            return NotFound(ApiResponse<CemeteryPredictionResultDto>.Fail("Groblje nije pronađeno."));
        return Ok(ApiResponse<CemeteryPredictionResultDto>.Ok(result));
    }

    [HttpGet("sva-groblja")]
    public async Task<ActionResult<ApiResponse<List<CemeteryPredictionResultDto>>>> GetForAll()
    {
        var cemeteryIds = await _db.Cemeteries
            .Where(c => c.IsActive)
            .OrderBy(c => c.Name)
            .Select(c => c.Id)
            .ToListAsync();

        var results = new List<CemeteryPredictionResultDto>();
        foreach (var id in cemeteryIds)
        {
            var prediction = await _predictionService.PredictAsync(id);
            if (prediction != null) results.Add(prediction);
        }

        return Ok(ApiResponse<List<CemeteryPredictionResultDto>>.Ok(results));
    }
}

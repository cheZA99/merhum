using System.Security.Claims;
using MerhumAPI.Common;
using MerhumAPI.DTOs.Chat;
using MerhumAPI.Services.Chat;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace MerhumAPI.Controllers;

[ApiController]
[Route("api/chat")]
[Authorize]
public class ChatController : ControllerBase
{
    private readonly IChatService _chatService;

    public ChatController(IChatService chatService) => _chatService = chatService;

    [HttpPost("message")]
    public async Task<ActionResult<ApiResponse<ChatResponseDto>>> SendMessage([FromBody] ChatRequestDto request)
    {
        if (request == null || string.IsNullOrWhiteSpace(request.Message))
            return BadRequest(ApiResponse<ChatResponseDto>.Fail("Poruka ne može biti prazna."));

        if (request.Message.Length > 2000)
            return BadRequest(ApiResponse<ChatResponseDto>.Fail("Poruka može imati najviše 2000 znakova."));

        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier)
                  ?? User.FindFirstValue("sub")
                  ?? throw new UnauthorizedAccessException();

        var result = await _chatService.SendMessageAsync(userId, request.Message.Trim());
        return Ok(ApiResponse<ChatResponseDto>.Ok(result));
    }

    [HttpGet("history")]
    public async Task<ActionResult<ApiResponse<List<ChatHistoryItemDto>>>> GetHistory(
        [FromQuery] int pageNumber = 1,
        [FromQuery] int pageSize = 20)
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier)
                  ?? User.FindFirstValue("sub")
                  ?? throw new UnauthorizedAccessException();

        var history = await _chatService.GetHistoryAsync(userId, pageNumber, pageSize);
        return Ok(ApiResponse<List<ChatHistoryItemDto>>.Ok(history));
    }

    [HttpDelete("history")]
    public async Task<ActionResult<ApiResponse<string>>> ClearHistory()
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier)
                  ?? User.FindFirstValue("sub")
                  ?? throw new UnauthorizedAccessException();

        await _chatService.ClearHistoryAsync(userId);
        return Ok(ApiResponse<string>.Ok("Historija razgovora je uspješno obrisana."));
    }
}

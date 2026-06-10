using MerhumAPI.Data;
using MerhumAPI.DTOs.Chat;
using MerhumAPI.Models;
using MerhumAPI.Services.Groq;
using Microsoft.EntityFrameworkCore;

namespace MerhumAPI.Services.Chat;

public class ChatService : IChatService
{
    private const int HistoryPairCount = 5;
    private const int ContextStoreLimit = 5000;

    private readonly ApplicationDbContext _db;
    private readonly IContextBuilderService _contextBuilder;
    private readonly IGroqService _groqService;
    private readonly ILogger<ChatService> _logger;

    public ChatService(
        ApplicationDbContext db,
        IContextBuilderService contextBuilder,
        IGroqService groqService,
        ILogger<ChatService> logger)
    {
        _db = db;
        _contextBuilder = contextBuilder;
        _groqService = groqService;
        _logger = logger;
    }

    public async Task<ChatResponseDto> SendMessageAsync(string userId, string message)
    {
        var dbContext = await _contextBuilder.BuildContextAsync(userId);

        var systemPrompt = $@"Vi ste Merhum asistent – ljubazan i profesionalan AI pomoćnik za porodice u procesu organizacije dženaza i pogreba u Bosni i Hercegovini.

VAŠA ULOGA:
- Pomažete porodicama korisnika u trenucima žalosti
- Pružate tačne informacije o grobljima, džamijama, imamima, terminima i uslugama
- Komunicirate isključivo na bosanskom jeziku, sa pažljivim i suosjećajnim tonom
- Koristite isključivo podatke iz baze (kontekst niže) – ne izmišljate informacije

PRAVILA:
1. Uvijek odgovarajte na bosanskom jeziku.
2. Koristite pristojne i suosjećajne izraze (npr. ""rahmetli"", ""Allah rahmetile"", ""molimo Vas"", ""Vaša porodica"").
3. Nikada ne izmišljajte podatke koji nisu u kontekstu – ako ne znate, recite to iskreno.
4. Pri navođenju cijena, kapaciteta i datuma koristite isključivo brojeve iz konteksta.
5. Kada korisnik pita o ""svojoj"" proceduri/terminu/preminulom, koristite samo zapise iz sekcije ""MOJE AKTIVNE PROCEDURE"".
6. Predlažite konkretne korake (npr. ""Možete zakazati termin kroz sekciju Termini u aplikaciji"") kada je prikladno.
7. Ako pitanje nije vezano za pogrebne procedure, ljubazno usmjerite korisnika na temu.
8. Odgovore držite kratkim i pregledim – maksimalno 4–6 rečenica osim ako je neophodno više.
9. Ne dijelite osjetljive lične podatke drugih korisnika.
10. Završite odgovor sa ohrabrujućom rečenicom ili izrazom saučešća kada je to prikladno.

KONTEKST IZ BAZE PODATAKA:
{dbContext}";

        var historyLogs = await _db.ChatLogs
            .Where(c => c.UserId == userId)
            .OrderByDescending(c => c.CreatedAt)
            .Take(HistoryPairCount)
            .ToListAsync();

        historyLogs.Reverse();

        var conversationHistory = new List<GroqMessage>();
        foreach (var log in historyLogs)
        {
            conversationHistory.Add(new GroqMessage { Role = "user", Content = log.Message });
            conversationHistory.Add(new GroqMessage { Role = "assistant", Content = log.Response });
        }

        var aiResponse = await _groqService.GetChatResponseAsync(systemPrompt, message, conversationHistory);

        var truncatedContext = dbContext.Length > ContextStoreLimit
            ? dbContext.Substring(0, ContextStoreLimit) + "..."
            : dbContext;

        var chatLog = new ChatLog
        {
            UserId = userId,
            Message = message,
            Response = aiResponse,
            Context = truncatedContext,
            CreatedAt = DateTime.UtcNow
        };

        _db.ChatLogs.Add(chatLog);
        await _db.SaveChangesAsync();

        _logger.LogInformation("Chat message processed for user {UserId}. ChatLogId: {ChatLogId}", userId, chatLog.Id);

        return new ChatResponseDto
        {
            Response = aiResponse,
            Timestamp = chatLog.CreatedAt,
            ChatLogId = chatLog.Id
        };
    }

    public async Task<List<ChatHistoryItemDto>> GetHistoryAsync(string userId, int pageNumber, int pageSize)
    {
        if (pageNumber < 1) pageNumber = 1;
        if (pageSize < 1) pageSize = 20;
        if (pageSize > 100) pageSize = 100;

        return await _db.ChatLogs
            .Where(c => c.UserId == userId)
            .OrderByDescending(c => c.CreatedAt)
            .Skip((pageNumber - 1) * pageSize)
            .Take(pageSize)
            .Select(c => new ChatHistoryItemDto
            {
                Id = c.Id,
                Message = c.Message,
                Response = c.Response,
                CreatedAt = c.CreatedAt
            })
            .ToListAsync();
    }

    public async Task<bool> ClearHistoryAsync(string userId)
    {
        var logs = await _db.ChatLogs.Where(c => c.UserId == userId).ToListAsync();
        if (logs.Count == 0) return false;
        _db.ChatLogs.RemoveRange(logs);
        await _db.SaveChangesAsync();
        return true;
    }
}

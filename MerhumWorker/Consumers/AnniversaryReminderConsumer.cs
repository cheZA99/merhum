using MassTransit;
using MerhumWorker.Messages;
using MerhumWorker.Services;

namespace MerhumWorker.Consumers;

public class AnniversaryReminderConsumer : IConsumer<AnniversaryReminderMessage>
{
    private readonly EmailService _emailService;
    private readonly IConfiguration _configuration;
    private readonly ILogger<AnniversaryReminderConsumer> _logger;

    public AnniversaryReminderConsumer(
        EmailService emailService,
        IConfiguration configuration,
        ILogger<AnniversaryReminderConsumer> logger)
    {
        _emailService = emailService;
        _configuration = configuration;
        _logger = logger;
    }

    public async Task Consume(ConsumeContext<AnniversaryReminderMessage> context)
    {
        var msg = context.Message;
        _logger.LogInformation("Processing AnniversaryReminder for DeceasedId={Id}, Years={Years}", msg.DeceasedId, msg.YearsElapsed);

        if (string.IsNullOrWhiteSpace(msg.ContactPersonEmail))
        {
            _logger.LogWarning("No contact email for anniversary reminder for deceased {Id}, skipping.", msg.DeceasedId);
            return;
        }

        var yearWord = msg.YearsElapsed == 1 ? "year" : "years";
        var obituaryLine = msg.ObituarySlug != null
            ? $"""<p>Visit the digital obituary: <a href="{_configuration["AppSettings:SmrtovnicaBaseUrl"]}/{msg.ObituarySlug}">View Obituary</a></p>"""
            : string.Empty;

        var subject = $"Remembering {msg.DeceasedFullName} — {msg.YearsElapsed} {yearWord}";
        var body = $"""
            <h2>Dear {msg.ContactPersonName},</h2>
            <p>Today marks <strong>{msg.YearsElapsed} {yearWord}</strong> since the passing of <strong>{msg.DeceasedFullName}</strong> on {msg.DateOfDeath:d}.</p>
            <p>May Allah grant them eternal peace and paradise.</p>
            {obituaryLine}
            <br/>
            <p>Merhum System</p>
            """;

        await _emailService.SendAsync(msg.ContactPersonEmail, msg.ContactPersonName, subject, body);
    }
}

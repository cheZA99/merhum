using MassTransit;
using MerhumWorker.Messages;
using MerhumWorker.Services;

namespace MerhumWorker.Consumers;

public class ObituaryCreatedConsumer : IConsumer<ObituaryCreatedMessage>
{
    private readonly EmailService _emailService;
    private readonly IConfiguration _configuration;
    private readonly ILogger<ObituaryCreatedConsumer> _logger;

    public ObituaryCreatedConsumer(
        EmailService emailService,
        IConfiguration configuration,
        ILogger<ObituaryCreatedConsumer> logger)
    {
        _emailService = emailService;
        _configuration = configuration;
        _logger = logger;
    }

    public async Task Consume(ConsumeContext<ObituaryCreatedMessage> context)
    {
        var msg = context.Message;
        _logger.LogInformation("Processing ObituaryCreated for ObituaryId={Id}, Slug={Slug}", msg.ObituaryId, msg.UniqueSlug);

        if (string.IsNullOrWhiteSpace(msg.ContactPersonEmail))
        {
            _logger.LogWarning("No contact email for obituary {Id}, skipping email.", msg.ObituaryId);
            return;
        }

        var baseUrl = _configuration["AppSettings:SmrtovnicaBaseUrl"] ?? "http://localhost:5000/smrtovnica";
        var obituaryUrl = $"{baseUrl}/{msg.UniqueSlug}";

        var subject = "Digital Obituary Created — Merhum System";
        var body = $"""
            <h2>Dear {msg.ContactPersonName},</h2>
            <p>A digital obituary has been created for <strong>{msg.DeceasedFullName}</strong>.</p>
            <p>You can view and share the obituary at the following link:</p>
            <p><a href="{obituaryUrl}">{obituaryUrl}</a></p>
            <p>The page allows visitors to leave condolences which will be reviewed before being published.</p>
            <br/>
            <p>Merhum System</p>
            """;

        await _emailService.SendAsync(msg.ContactPersonEmail, msg.ContactPersonName, subject, body);
    }
}

using MassTransit;
using MerhumWorker.Messages;
using MerhumWorker.Services;
using MerhumWorker.Templates;

namespace MerhumWorker.Consumers;

public class AnniversaryReminderConsumer : IConsumer<AnniversaryReminderMessage>
{
    private readonly IEmailService _emailService;
    private readonly IConfiguration _configuration;
    private readonly ILogger<AnniversaryReminderConsumer> _logger;

    public AnniversaryReminderConsumer(
        IEmailService emailService,
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
        _logger.LogInformation("Received AnniversaryReminder DeceasedId={Id} Years={Years}", msg.DeceasedId, msg.YearsElapsed);

        if (string.IsNullOrWhiteSpace(msg.ContactPersonEmail))
        {
            _logger.LogWarning("No contact email for anniversary reminder of deceased {Id}, skipping.", msg.DeceasedId);
            return;
        }

        string? obituaryUrl = null;
        if (!string.IsNullOrWhiteSpace(msg.ObituarySlug))
        {
            var baseUrl = _configuration["AppSettings:ObituaryBaseUrl"]
                          ?? _configuration["AppSettings:SmrtovnicaBaseUrl"]
                          ?? "http://localhost:5000/smrtovnica";
            obituaryUrl = $"{baseUrl.TrimEnd('/')}/{msg.ObituarySlug}";
        }

        var body = AnniversaryTemplate.Build(msg, obituaryUrl);
        var subject = AnniversaryTemplate.BuildSubject(msg);
        await _emailService.SendEmailAsync(msg.ContactPersonEmail, msg.ContactPersonName, subject, body);
    }
}

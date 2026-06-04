using MassTransit;
using MerhumWorker.Messages;
using MerhumWorker.Services;
using MerhumWorker.Templates;

namespace MerhumWorker.Consumers;

public class ObituaryCreatedConsumer : IConsumer<ObituaryCreatedMessage>
{
    private readonly IEmailService _emailService;
    private readonly IConfiguration _configuration;
    private readonly ILogger<ObituaryCreatedConsumer> _logger;

    public ObituaryCreatedConsumer(
        IEmailService emailService,
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
        _logger.LogInformation("Received ObituaryCreated ObituaryId={Id} Slug={Slug}", msg.ObituaryId, msg.UniqueSlug);

        if (string.IsNullOrWhiteSpace(msg.ContactPersonEmail))
        {
            _logger.LogWarning("No contact email for obituary {Id}, skipping email.", msg.ObituaryId);
            return;
        }

        var baseUrl = _configuration["AppSettings:ObituaryBaseUrl"]
                      ?? _configuration["AppSettings:SmrtovnicaBaseUrl"]
                      ?? "http://localhost:5000/smrtovnica";
        var obituaryUrl = $"{baseUrl.TrimEnd('/')}/{msg.UniqueSlug}";

        var body = ObituaryCreatedTemplate.Build(msg, obituaryUrl);
        var subject = ObituaryCreatedTemplate.BuildSubject(msg);
        await _emailService.SendEmailAsync(msg.ContactPersonEmail, msg.ContactPersonName, subject, body);
    }
}

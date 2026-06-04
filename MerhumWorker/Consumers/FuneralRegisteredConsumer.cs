using MassTransit;
using MerhumWorker.Messages;
using MerhumWorker.Services;
using MerhumWorker.Templates;

namespace MerhumWorker.Consumers;

public class FuneralRegisteredConsumer : IConsumer<FuneralRegisteredMessage>
{
    private readonly IEmailService _emailService;
    private readonly ILogger<FuneralRegisteredConsumer> _logger;

    public FuneralRegisteredConsumer(IEmailService emailService, ILogger<FuneralRegisteredConsumer> logger)
    {
        _emailService = emailService;
        _logger = logger;
    }

    public async Task Consume(ConsumeContext<FuneralRegisteredMessage> context)
    {
        var msg = context.Message;
        _logger.LogInformation("Received FuneralRegistered DeceasedId={Id} Name={Name}", msg.DeceasedId, msg.FullName);

        if (string.IsNullOrWhiteSpace(msg.ContactPersonEmail))
        {
            _logger.LogWarning("No contact email for deceased {Id}, skipping email.", msg.DeceasedId);
            return;
        }

        var body = FuneralRegisteredTemplate.Build(msg);
        await _emailService.SendEmailAsync(msg.ContactPersonEmail, msg.ContactPersonName, FuneralRegisteredTemplate.Subject, body);
    }
}

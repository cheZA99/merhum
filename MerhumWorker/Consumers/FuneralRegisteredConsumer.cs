using MassTransit;
using MerhumWorker.Messages;
using MerhumWorker.Services;

namespace MerhumWorker.Consumers;

public class FuneralRegisteredConsumer : IConsumer<FuneralRegisteredMessage>
{
    private readonly EmailService _emailService;
    private readonly ILogger<FuneralRegisteredConsumer> _logger;

    public FuneralRegisteredConsumer(EmailService emailService, ILogger<FuneralRegisteredConsumer> logger)
    {
        _emailService = emailService;
        _logger = logger;
    }

    public async Task Consume(ConsumeContext<FuneralRegisteredMessage> context)
    {
        var msg = context.Message;
        _logger.LogInformation("Processing FuneralRegistered for DeceasedId={Id}, Name={Name}", msg.DeceasedId, msg.FullName);

        if (string.IsNullOrWhiteSpace(msg.ContactPersonEmail))
        {
            _logger.LogWarning("No contact email for deceased {Id}, skipping email.", msg.DeceasedId);
            return;
        }

        var subject = "Funeral Registration Confirmed — Merhum System";
        var body = $"""
            <h2>Dear {msg.ContactPersonName},</h2>
            <p>The funeral procedure for <strong>{msg.FullName}</strong> has been registered in the Merhum system.</p>
            <p>Registration date: {msg.RegisteredAt:f}</p>
            <p>Our team will be in touch shortly to confirm the next steps.</p>
            <br/>
            <p>Merhum System</p>
            """;

        await _emailService.SendAsync(msg.ContactPersonEmail, msg.ContactPersonName, subject, body);
    }
}

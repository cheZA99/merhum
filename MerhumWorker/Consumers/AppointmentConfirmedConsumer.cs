using MassTransit;
using MerhumWorker.Messages;
using MerhumWorker.Services;
using MerhumWorker.Templates;

namespace MerhumWorker.Consumers;

public class AppointmentConfirmedConsumer : IConsumer<AppointmentConfirmedMessage>
{
    private readonly IEmailService _emailService;
    private readonly ILogger<AppointmentConfirmedConsumer> _logger;

    public AppointmentConfirmedConsumer(IEmailService emailService, ILogger<AppointmentConfirmedConsumer> logger)
    {
        _emailService = emailService;
        _logger = logger;
    }

    public async Task Consume(ConsumeContext<AppointmentConfirmedMessage> context)
    {
        var msg = context.Message;
        _logger.LogInformation("Received AppointmentConfirmed AppointmentId={Id}", msg.AppointmentId);

        if (string.IsNullOrWhiteSpace(msg.ContactPersonEmail))
        {
            _logger.LogWarning("No family email for appointment {Id}, skipping email.", msg.AppointmentId);
            return;
        }

        var body = AppointmentConfirmedTemplate.Build(msg);
        var subject = AppointmentConfirmedTemplate.BuildSubject(msg);
        await _emailService.SendEmailAsync(msg.ContactPersonEmail, $"Porodica {msg.DeceasedFullName}", subject, body);
    }
}

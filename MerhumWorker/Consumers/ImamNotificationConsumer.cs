using MassTransit;
using MerhumWorker.Messages;
using MerhumWorker.Services;
using MerhumWorker.Templates;

namespace MerhumWorker.Consumers;

public class ImamNotificationConsumer : IConsumer<ImamNotificationMessage>
{
    private readonly IEmailService _emailService;
    private readonly ILogger<ImamNotificationConsumer> _logger;

    public ImamNotificationConsumer(IEmailService emailService, ILogger<ImamNotificationConsumer> logger)
    {
        _emailService = emailService;
        _logger = logger;
    }

    public async Task Consume(ConsumeContext<ImamNotificationMessage> context)
    {
        var msg = context.Message;
        _logger.LogInformation("Received ImamNotification ImamId={Id} AppointmentId={AptId}", msg.ImamId, msg.AppointmentId);

        if (string.IsNullOrWhiteSpace(msg.ImamEmail))
        {
            _logger.LogWarning("No imam email for appointment {Id}, skipping email.", msg.AppointmentId);
            return;
        }

        var body = ImamNotificationTemplate.Build(msg);
        var subject = ImamNotificationTemplate.BuildSubject(msg);
        await _emailService.SendEmailAsync(msg.ImamEmail, msg.ImamFullName, subject, body);
    }
}

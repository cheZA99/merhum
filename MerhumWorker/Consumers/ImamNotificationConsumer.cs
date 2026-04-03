using MassTransit;
using MerhumWorker.Messages;
using MerhumWorker.Services;

namespace MerhumWorker.Consumers;

public class ImamNotificationConsumer : IConsumer<ImamNotificationMessage>
{
    private readonly EmailService _emailService;
    private readonly ILogger<ImamNotificationConsumer> _logger;

    public ImamNotificationConsumer(EmailService emailService, ILogger<ImamNotificationConsumer> logger)
    {
        _emailService = emailService;
        _logger = logger;
    }

    public async Task Consume(ConsumeContext<ImamNotificationMessage> context)
    {
        var msg = context.Message;
        _logger.LogInformation("Processing ImamNotification for ImamId={Id}, AppointmentId={AptId}", msg.ImamId, msg.AppointmentId);

        var subject = "Funeral Prayer Assignment — Merhum System";
        var body = $"""
            <h2>Dear {msg.ImamFullName},</h2>
            <p>You have been assigned to lead the funeral prayer for <strong>{msg.DeceasedFullName}</strong>.</p>
            <ul>
                <li><strong>Date and time:</strong> {msg.FuneralDateTime:f}</li>
                <li><strong>Mosque:</strong> {msg.MosqueName}</li>
                <li><strong>Cemetery:</strong> {msg.CemeteryName}</li>
            </ul>
            <p>Please confirm your availability or contact us if you have any questions.</p>
            <br/>
            <p>Merhum System</p>
            """;

        await _emailService.SendAsync(msg.ImamEmail, msg.ImamFullName, subject, body);
    }
}

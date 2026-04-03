using MassTransit;
using MerhumWorker.Messages;
using MerhumWorker.Services;

namespace MerhumWorker.Consumers;

public class AppointmentConfirmedConsumer : IConsumer<AppointmentConfirmedMessage>
{
    private readonly EmailService _emailService;
    private readonly ILogger<AppointmentConfirmedConsumer> _logger;

    public AppointmentConfirmedConsumer(EmailService emailService, ILogger<AppointmentConfirmedConsumer> logger)
    {
        _emailService = emailService;
        _logger = logger;
    }

    public async Task Consume(ConsumeContext<AppointmentConfirmedMessage> context)
    {
        var msg = context.Message;
        _logger.LogInformation("Processing AppointmentConfirmed for AppointmentId={Id}", msg.AppointmentId);

        if (string.IsNullOrWhiteSpace(msg.ContactPersonEmail))
        {
            _logger.LogWarning("No contact email for appointment {Id}, skipping email.", msg.AppointmentId);
            return;
        }

        var imamLine = msg.ImamFullName != null
            ? $"<li><strong>Imam:</strong> {msg.ImamFullName}</li>"
            : string.Empty;

        var subject = "Funeral Appointment Confirmed — Merhum System";
        var body = $"""
            <h2>Dear Family of {msg.DeceasedFullName},</h2>
            <p>The funeral appointment has been scheduled. Details are as follows:</p>
            <ul>
                <li><strong>Date and time:</strong> {msg.FuneralDateTime:f}</li>
                <li><strong>Mosque:</strong> {msg.MosqueName}</li>
                <li><strong>Cemetery:</strong> {msg.CemeteryName}</li>
                {imamLine}
            </ul>
            <p>Please contact us if you have any questions.</p>
            <br/>
            <p>Merhum System</p>
            """;

        await _emailService.SendAsync(msg.ContactPersonEmail, $"Family of {msg.DeceasedFullName}", subject, body);
    }
}

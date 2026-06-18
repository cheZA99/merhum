using MassTransit;
using MerhumWorker.Messages;
using MerhumWorker.Services;
using MerhumWorker.Templates;

namespace MerhumWorker.Consumers;

public class PaymentCompletedConsumer : IConsumer<PaymentCompletedMessage>
{
    private readonly IEmailService _emailService;
    private readonly ILogger<PaymentCompletedConsumer> _logger;

    public PaymentCompletedConsumer(IEmailService emailService, ILogger<PaymentCompletedConsumer> logger)
    {
        _emailService = emailService;
        _logger = logger;
    }

    public async Task Consume(ConsumeContext<PaymentCompletedMessage> context)
    {
        var msg = context.Message;
        _logger.LogInformation("Received PaymentCompleted PaymentId={Id} OrderId={OrderId}", msg.PaymentId, msg.ServiceOrderId);

        if (string.IsNullOrWhiteSpace(msg.RecipientEmail))
        {
            _logger.LogWarning("No recipient email for payment {Id}, skipping email.", msg.PaymentId);
            return;
        }

        var subject = PaymentCompletedTemplate.BuildSubject(msg);
        var body = PaymentCompletedTemplate.BuildBody(msg);
        await _emailService.SendEmailAsync(msg.RecipientEmail, msg.RecipientName, subject, body);
    }
}

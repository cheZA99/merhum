using MassTransit;
using MerhumWorker.Messages;
using MerhumWorker.Services;
using MerhumWorker.Templates;

namespace MerhumWorker.Consumers;

public class ServiceOrderedConsumer : IConsumer<ServiceOrderedMessage>
{
    private readonly IEmailService _emailService;
    private readonly ILogger<ServiceOrderedConsumer> _logger;

    public ServiceOrderedConsumer(IEmailService emailService, ILogger<ServiceOrderedConsumer> logger)
    {
        _emailService = emailService;
        _logger = logger;
    }

    public async Task Consume(ConsumeContext<ServiceOrderedMessage> context)
    {
        var msg = context.Message;
        _logger.LogInformation("Received ServiceOrdered OrderId={Id} FuneralHome={Home}", msg.ServiceOrderId, msg.FuneralHomeName);

        if (string.IsNullOrWhiteSpace(msg.FuneralHomeEmail))
        {
            _logger.LogWarning("No funeral home email for order {Id}, skipping email.", msg.ServiceOrderId);
            return;
        }

        var body = ServiceOrderedTemplate.BuildFuneralHomeBody(msg);
        var subject = ServiceOrderedTemplate.BuildFuneralHomeSubject(msg);
        await _emailService.SendEmailAsync(msg.FuneralHomeEmail, msg.FuneralHomeName, subject, body);
    }
}

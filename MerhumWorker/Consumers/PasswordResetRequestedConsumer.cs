using MassTransit;
using MerhumContracts;
using MerhumWorker.Services;
using MerhumWorker.Templates;

namespace MerhumWorker.Consumers;

public class PasswordResetRequestedConsumer : IConsumer<PasswordResetRequestedMessage>
{
    private readonly IEmailService _emailService;
    private readonly ILogger<PasswordResetRequestedConsumer> _logger;

    public PasswordResetRequestedConsumer(IEmailService emailService, ILogger<PasswordResetRequestedConsumer> logger)
    {
        _emailService = emailService;
        _logger = logger;
    }

    public async Task Consume(ConsumeContext<PasswordResetRequestedMessage> context)
    {
        var msg = context.Message;
        _logger.LogInformation("Received PasswordResetRequested for {Email}", msg.Email);

        var body = PasswordResetTemplate.Build(msg);
        await _emailService.SendEmailAsync(msg.Email, msg.FullName, PasswordResetTemplate.BuildSubject(), body);
    }
}

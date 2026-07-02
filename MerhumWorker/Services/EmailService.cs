using MailKit.Net.Smtp;
using MailKit.Security;
using MimeKit;

namespace MerhumWorker.Services;

public class EmailService : IEmailService
{
    private readonly IConfiguration _configuration;
    private readonly ILogger<EmailService> _logger;

    public EmailService(IConfiguration configuration, ILogger<EmailService> logger)
    {
        _configuration = configuration;
        _logger = logger;
    }

    public async Task SendEmailAsync(string toEmail, string toName, string subject, string htmlBody)
    {
        var smtpHost = _configuration["SMTP:Host"] ?? throw new InvalidOperationException("SMTP:Host missing");
        var smtpPort = int.Parse(_configuration["SMTP:Port"] ?? "587");
        var smtpUser = _configuration["SMTP:Username"] ?? throw new InvalidOperationException("SMTP:Username missing");
        var smtpPass = _configuration["SMTP:Password"] ?? throw new InvalidOperationException("SMTP:Password missing");
        var useSsl = bool.Parse(_configuration["SMTP:UseSSL"] ?? "true");
        var senderName = _configuration["SMTP:SenderName"] ?? "Merhum Sistem";
        var senderEmail = _configuration["SMTP:SenderEmail"] ?? smtpUser;

        var message = new MimeMessage();
        message.From.Add(new MailboxAddress(senderName, senderEmail));
        message.To.Add(new MailboxAddress(toName, toEmail));
        message.Subject = subject;
        message.Body = new BodyBuilder { HtmlBody = htmlBody }.ToMessageBody();

        using var client = new SmtpClient();
        try
        {
            var secureOption = useSsl ? SecureSocketOptions.StartTls : SecureSocketOptions.None;
            await client.ConnectAsync(smtpHost, smtpPort, secureOption);
            await client.AuthenticateAsync(smtpUser, smtpPass);
            await client.SendAsync(message);
            _logger.LogInformation("Email sent to {Email} - Subject: {Subject}", toEmail, subject);
        }
        catch (Exception ex)
        {
            // don't rethrow, avoids endless requeue on bad SMTP/address
            _logger.LogError(ex, "Failed to send email to {Email} - Subject: {Subject}", toEmail, subject);
        }
        finally
        {
            if (client.IsConnected)
            {
                await client.DisconnectAsync(true);
            }
        }
    }
}

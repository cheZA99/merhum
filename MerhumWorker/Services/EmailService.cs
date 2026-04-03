using MailKit.Net.Smtp;
using MailKit.Security;
using MimeKit;

namespace MerhumWorker.Services;

public class EmailService
{
    private readonly IConfiguration _configuration;
    private readonly ILogger<EmailService> _logger;

    public EmailService(IConfiguration configuration, ILogger<EmailService> logger)
    {
        _configuration = configuration;
        _logger = logger;
    }

    public async Task SendAsync(string toEmail, string toName, string subject, string htmlBody)
    {
        var smtpHost = _configuration["SMTP:Host"] ?? throw new InvalidOperationException("SMTP:Host missing");
        var smtpPort = int.Parse(_configuration["SMTP:Port"] ?? "587");
        var smtpUser = _configuration["SMTP:Username"] ?? throw new InvalidOperationException("SMTP:Username missing");
        var smtpPass = _configuration["SMTP:Password"] ?? throw new InvalidOperationException("SMTP:Password missing");
        var useSsl = bool.Parse(_configuration["SMTP:UseSSL"] ?? "true");
        var senderName = _configuration["SMTP:SenderName"] ?? "Merhum System";

        var message = new MimeMessage();
        message.From.Add(new MailboxAddress(senderName, smtpUser));
        message.To.Add(new MailboxAddress(toName, toEmail));
        message.Subject = subject;

        var builder = new BodyBuilder { HtmlBody = htmlBody };
        message.Body = builder.ToMessageBody();

        using var client = new SmtpClient();
        try
        {
            var secureOption = useSsl ? SecureSocketOptions.StartTls : SecureSocketOptions.None;
            await client.ConnectAsync(smtpHost, smtpPort, secureOption);
            await client.AuthenticateAsync(smtpUser, smtpPass);
            await client.SendAsync(message);
            _logger.LogInformation("Email sent to {Email} — Subject: {Subject}", toEmail, subject);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to send email to {Email}", toEmail);
            throw;
        }
        finally
        {
            await client.DisconnectAsync(true);
        }
    }
}

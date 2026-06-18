using MerhumWorker.Messages;

namespace MerhumWorker.Templates;

internal static class PaymentCompletedTemplate
{
    public static string BuildSubject(PaymentCompletedMessage m) =>
        $"Potvrda plaćanja - {m.ServiceTypeName}";

    public static string BuildBody(PaymentCompletedMessage m)
    {
        var inner = $"""
            <p>Esselamu alejkum {m.RecipientName},</p>
            <p>Vaše plaćanje je uspješno zaprimljeno. Hvala Vam.</p>
            <p>Detalji:</p>
            <ul>
                <li><strong>Usluga:</strong> {m.ServiceTypeName}</li>
                <li><strong>Iznos:</strong> {m.Amount:0.00} {m.Currency}</li>
                <li><strong>Datum plaćanja:</strong> {m.CompletedAt.ToString(EmailLayout.DateFormat)}</li>
            </ul>
            <p>Ovo plaćanje možete koristiti kao potvrdu o izvršenoj uplati.</p>
            """;
        return EmailLayout.Wrap(inner);
    }
}

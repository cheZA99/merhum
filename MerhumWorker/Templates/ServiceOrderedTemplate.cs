using MerhumWorker.Messages;

namespace MerhumWorker.Templates;

internal static class ServiceOrderedTemplate
{
    public static string BuildFuneralHomeSubject(ServiceOrderedMessage m) =>
        $"Nova narudžba usluge - {m.DeceasedFullName}";

    public static string BuildFuneralHomeBody(ServiceOrderedMessage m)
    {
        var inner = $"""
            <p>Esselamu alejkum,</p>
            <p>Pogrebno preduzeće <strong>{m.FuneralHomeName}</strong> primilo je novu narudžbu usluge u Merhum sistemu.</p>
            <p>Detalji:</p>
            <ul>
                <li><strong>Usluga:</strong> {m.ServiceTypeName}</li>
                <li><strong>Cijena:</strong> {m.Price:0.00} KM</li>
                <li><strong>Rahmetli:</strong> {m.DeceasedFullName}</li>
                <li><strong>Datum narudžbe:</strong> {m.OrderedAt.ToString(EmailLayout.DateFormat)}</li>
            </ul>
            <p>Molimo Vas da pristupite Merhum aplikaciji i potvrdite prijem narudžbe.</p>
            """;
        return EmailLayout.Wrap(inner);
    }
}

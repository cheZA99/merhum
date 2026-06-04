using MerhumWorker.Messages;

namespace MerhumWorker.Templates;

internal static class FuneralRegisteredTemplate
{
    public const string Subject = "Potvrda prijave preminulog - Merhum sistem";

    public static string Build(FuneralRegisteredMessage m)
    {
        var inner = $"""
            <p>Esselamu alejkum, {m.ContactPersonName},</p>
            <p>Potvrđujemo da je prijava za rahmetli <strong>{m.FullName}</strong> uspješno zaprimljena u Merhum sistem.</p>
            <p>Datum prijave: <strong>{m.RegisteredAt.ToString(EmailLayout.DateFormat)}</strong></p>
            <p>Vaš zahtjev je sada u fazi <em>Prijavljen</em> i administratori sistema će u najkraćem roku obraditi dokumentaciju.</p>
            <p>Slijedeći koraci:</p>
            <ul>
                <li>Provjera i potvrda dokumentacije</li>
                <li>Zakazivanje termina dženaze</li>
                <li>Narudžba pogrebnih usluga</li>
                <li>Kreiranje smrtovnice</li>
            </ul>
            <p>Status procedure možete pratiti u Merhum mobilnoj aplikaciji.</p>
            <p>Allah dž.š. dao rahmet rahmetli {m.FullName}.</p>
            """;
        return EmailLayout.Wrap(inner);
    }
}

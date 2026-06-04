using MerhumWorker.Messages;

namespace MerhumWorker.Templates;

internal static class AppointmentConfirmedTemplate
{
    public static string BuildSubject(AppointmentConfirmedMessage m) =>
        $"Termin dženaze je zakazan - {m.DeceasedFullName}";

    public static string Build(AppointmentConfirmedMessage m)
    {
        var imamRow = !string.IsNullOrWhiteSpace(m.ImamFullName)
            ? $"<li><strong>Imam:</strong> {m.ImamFullName}</li>"
            : string.Empty;

        var inner = $"""
            <p>Esselamu alejkum,</p>
            <p>Termin dženaze za rahmetli <strong>{m.DeceasedFullName}</strong> je uspješno zakazan.</p>
            <p>Detalji dženaze:</p>
            <ul>
                <li><strong>Datum i sat:</strong> {m.FuneralDateTime.ToString(EmailLayout.DateFormat)}</li>
                <li><strong>Mesdžid:</strong> {m.MosqueName}</li>
                <li><strong>Groblje:</strong> {m.CemeteryName}</li>
                {imamRow}
            </ul>
            <p>Molimo Vas da obavijestite rodbinu i prijatelje.</p>
            <p>Detalje termina možete vidjeti i u Merhum mobilnoj aplikaciji.</p>
            """;
        return EmailLayout.Wrap(inner);
    }
}

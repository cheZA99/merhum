using MerhumWorker.Messages;

namespace MerhumWorker.Templates;

internal static class ImamNotificationTemplate
{
    public static string BuildSubject(ImamNotificationMessage m) =>
        $"Zakazana dženaza - {m.FuneralDateTime.ToString(EmailLayout.DateFormat)}";

    public static string Build(ImamNotificationMessage m)
    {
        var inner = $"""
            <p>Esselamu alejkum, {m.ImamFullName},</p>
            <p>Obavještavamo Vas da je zakazana dženaza u mesdžidu <strong>{m.MosqueName}</strong> koju ćete predvoditi.</p>
            <p>Detalji:</p>
            <ul>
                <li><strong>Rahmetli:</strong> {m.DeceasedFullName}</li>
                <li><strong>Datum i sat:</strong> {m.FuneralDateTime.ToString(EmailLayout.DateFormat)}</li>
                <li><strong>Mesdžid:</strong> {m.MosqueName}</li>
                <li><strong>Groblje:</strong> {m.CemeteryName}</li>
            </ul>
            <p>Molimo Vas da potvrdite svoju dostupnost putem Merhum aplikacije ili kontaktirate porodicu direktno.</p>
            """;
        return EmailLayout.Wrap(inner);
    }
}

using MerhumWorker.Messages;

namespace MerhumWorker.Templates;

internal static class AnniversaryTemplate
{
    public static string BuildSubject(AnniversaryReminderMessage m) =>
        $"Godišnjica - {m.DeceasedFullName}";

    public static string Build(AnniversaryReminderMessage m, string? obituaryUrl)
    {
        var dateText = m.DateOfDeath.ToString("dd.MM.yyyy.");
        var obituaryBlock = obituaryUrl != null
            ? $"""<p>Digitalna smrtovnica: <a href="{obituaryUrl}" style="color:#1B5E20;">{obituaryUrl}</a></p>"""
            : string.Empty;

        var inner = $"""
            <p>Esselamu alejkum, {m.ContactPersonName},</p>
            <p>Danas se navršava <strong>{m.YearsElapsed}</strong> godina od preseljenja rahmetli <strong>{m.DeceasedFullName}</strong> na ahiret ({dateText}).</p>
            <p>Ova godišnjica može biti prilika za zajednički tevhid, proučavanje Jasin sure ili druge ibadete u sjećanje na rahmetli {m.DeceasedFullName}.</p>
            <p>Allah dž.š. dao mu/joj rahmet i učinio da Dženet bude njegovo/njeno vječno boravište.</p>
            {obituaryBlock}
            """;
        return EmailLayout.Wrap(inner);
    }
}

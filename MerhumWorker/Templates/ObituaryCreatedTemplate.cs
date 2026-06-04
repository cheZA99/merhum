using MerhumWorker.Messages;

namespace MerhumWorker.Templates;

internal static class ObituaryCreatedTemplate
{
    public static string BuildSubject(ObituaryCreatedMessage m) =>
        $"Smrtovnica je kreirana - {m.DeceasedFullName}";

    public static string Build(ObituaryCreatedMessage m, string obituaryUrl)
    {
        var inner = $"""
            <p>Esselamu alejkum, {m.ContactPersonName},</p>
            <p>Digitalna smrtovnica za rahmetli <strong>{m.DeceasedFullName}</strong> je uspješno kreirana.</p>
            <p>Smrtovnicu možete pogledati i podijeliti putem linka:</p>
            <p><a href="{obituaryUrl}" style="color:#1B5E20;">{obituaryUrl}</a></p>
            <p>Također, u sklopu smrtovnice se nalazi QR kod koji možete odštampati i postaviti na nišan.</p>
            <p>Smrtovnicu možete dijeliti putem:</p>
            <ul>
                <li>WhatsApp</li>
                <li>Viber</li>
                <li>Email</li>
                <li>Direktan link</li>
            </ul>
            <p>Allah dž.š. dao rahmet rahmetli {m.DeceasedFullName}.</p>
            """;
        return EmailLayout.Wrap(inner);
    }
}

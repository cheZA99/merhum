using MerhumContracts;

namespace MerhumWorker.Templates;

internal static class PasswordResetTemplate
{
    public static string BuildSubject() => "Zahtjev za promjenu lozinke";

    public static string Build(PasswordResetRequestedMessage m)
    {
        var inner = $"""
            <p>Esselamu alejkum, {m.FullName},</p>
            <p>Zaprimili smo zahtjev za promjenu lozinke na Vašem Merhum nalogu.</p>
            <p>U aplikaciji unesite sljedeći kod da postavite novu lozinku:</p>
            <p style="font-size:16px;"><strong>{m.Token}</strong></p>
            <p>Ako niste Vi tražili promjenu lozinke, ovu poruku možete zanemariti. Vaša lozinka
            ostaje nepromijenjena sve dok se kod ne iskoristi.</p>
            """;
        return EmailLayout.Wrap(inner);
    }
}

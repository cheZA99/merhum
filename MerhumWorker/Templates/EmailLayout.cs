namespace MerhumWorker.Templates;

internal static class EmailLayout
{
    public const string DateFormat = "dd.MM.yyyy. u HH:mm";

    public static string Wrap(string innerHtml) => $$"""
        <!DOCTYPE html>
        <html lang="bs">
        <head><meta charset="utf-8"/></head>
        <body style="margin:0;padding:0;background:#f5f5f5;font-family:Arial,Helvetica,sans-serif;color:#222;">
            <table width="100%" cellpadding="0" cellspacing="0" border="0">
                <tr><td align="center" style="padding:24px;">
                    <table width="600" cellpadding="0" cellspacing="0" border="0" style="max-width:600px;background:#ffffff;border:1px solid #e0e0e0;">
                        <tr><td style="background:#1B5E20;color:#ffffff;padding:16px 24px;font-size:20px;font-weight:bold;">Merhum sistem</td></tr>
                        <tr><td style="padding:24px;font-size:15px;line-height:1.6;">{{innerHtml}}</td></tr>
                        <tr><td style="padding:16px 24px;background:#fafafa;color:#777;font-size:12px;border-top:1px solid #e0e0e0;">
                            Ovo je automatska poruka iz Merhum sistema. Molimo ne odgovarajte na ovaj email.
                        </td></tr>
                    </table>
                </td></tr>
            </table>
        </body>
        </html>
        """;
}

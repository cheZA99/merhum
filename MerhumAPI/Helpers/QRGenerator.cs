using QRCoder;
using System.Drawing;

namespace MerhumAPI.Helpers;

public static class QRGenerator
{
    public static string GenerateAndSave(string url, string slug)
    {
        using var generator = new QRCodeGenerator();
        var data = generator.CreateQrCode(url, QRCodeGenerator.ECCLevel.Q);
        using var code = new PngByteQRCode(data);
        var bytes = code.GetGraphic(5);

        var folder = Path.Combine("wwwroot", "qrcodes");
        Directory.CreateDirectory(folder);

        var fileName = $"{slug}.png";
        var filePath = Path.Combine(folder, fileName);
        File.WriteAllBytes(filePath, bytes);

        return $"/qrcodes/{fileName}";
    }

    public static byte[] GenerateBytes(string url)
    {
        using var generator = new QRCodeGenerator();
        var data = generator.CreateQrCode(url, QRCodeGenerator.ECCLevel.Q);
        using var code = new PngByteQRCode(data);
        return code.GetGraphic(5);
    }
}

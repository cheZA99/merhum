namespace MerhumAPI.Common;

// an extension says nothing about what is actually in the file, so the first bytes are checked too
public static class ImageUpload
{
    public const long MaxBytes = 5 * 1024 * 1024;

    private static readonly Dictionary<string, byte[][]> Signatures = new()
    {
        [".jpg"] = new[] { new byte[] { 0xFF, 0xD8, 0xFF } },
        [".jpeg"] = new[] { new byte[] { 0xFF, 0xD8, 0xFF } },
        [".png"] = new[] { new byte[] { 0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A } },
        [".webp"] = new[] { new byte[] { 0x52, 0x49, 0x46, 0x46 } }
    };

    private static readonly Dictionary<string, string[]> MimeTypes = new()
    {
        [".jpg"] = new[] { "image/jpeg" },
        [".jpeg"] = new[] { "image/jpeg" },
        [".png"] = new[] { "image/png" },
        [".webp"] = new[] { "image/webp" }
    };

    public static async Task<string?> ValidateAsync(IFormFile? file)
    {
        if (file == null || file.Length == 0)
            return "Datoteka nije poslana.";

        if (file.Length > MaxBytes)
            return "Slika ne smije biti veća od 5 MB.";

        var extension = Path.GetExtension(file.FileName).ToLowerInvariant();
        if (!Signatures.TryGetValue(extension, out var allowedSignatures))
            return "Dozvoljene su samo .jpg, .jpeg, .png i .webp slike.";

        if (!MimeTypes[extension].Contains(file.ContentType))
            return "Tip sadržaja ne odgovara ekstenziji datoteke.";

        var header = new byte[8];
        await using (var stream = file.OpenReadStream())
        {
            var read = await stream.ReadAsync(header);
            if (read < allowedSignatures[0].Length)
                return "Datoteka nije ispravna slika.";
        }

        var matches = allowedSignatures.Any(signature => header.Take(signature.Length).SequenceEqual(signature));
        if (!matches)
            return "Sadržaj datoteke ne odgovara slici tog formata.";

        // webp keeps the format marker after the RIFF size field
        if (extension == ".webp" && !await HasWebPMarkerAsync(file))
            return "Sadržaj datoteke ne odgovara slici tog formata.";

        return null;
    }

    private static async Task<bool> HasWebPMarkerAsync(IFormFile file)
    {
        var header = new byte[12];
        await using var stream = file.OpenReadStream();
        var read = await stream.ReadAsync(header);
        if (read < 12) return false;

        return header[8] == 0x57 && header[9] == 0x45 && header[10] == 0x42 && header[11] == 0x50;
    }
}

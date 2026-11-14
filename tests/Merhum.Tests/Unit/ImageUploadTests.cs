using MerhumAPI.Common;
using Microsoft.AspNetCore.Http;

namespace Merhum.Tests.Unit;

public class ImageUploadTests
{
    private static readonly byte[] PngHeader = { 0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D };
    private static readonly byte[] JpegHeader = { 0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01 };
    private static readonly byte[] WebPHeader = { 0x52, 0x49, 0x46, 0x46, 0x24, 0x00, 0x00, 0x00, 0x57, 0x45, 0x42, 0x50 };

    private static IFormFile CreateFile(string fileName, string contentType, byte[] content)
    {
        return new FormFile(new MemoryStream(content), 0, content.Length, "file", fileName)
        {
            Headers = new HeaderDictionary(),
            ContentType = contentType
        };
    }

    [Theory]
    [InlineData("photo.png", "image/png")]
    [InlineData("PHOTO.PNG", "image/png")]
    public async Task Accepts_a_real_png(string fileName, string contentType)
    {
        Assert.Null(await ImageUpload.ValidateAsync(CreateFile(fileName, contentType, PngHeader)));
    }

    [Fact]
    public async Task Accepts_a_real_jpeg_and_webp()
    {
        Assert.Null(await ImageUpload.ValidateAsync(CreateFile("a.jpg", "image/jpeg", JpegHeader)));
        Assert.Null(await ImageUpload.ValidateAsync(CreateFile("a.webp", "image/webp", WebPHeader)));
    }

    [Fact]
    public async Task Rejects_missing_or_empty_file()
    {
        Assert.NotNull(await ImageUpload.ValidateAsync(null));
        Assert.NotNull(await ImageUpload.ValidateAsync(CreateFile("a.png", "image/png", Array.Empty<byte>())));
    }

    [Fact]
    public async Task Rejects_disallowed_extension()
    {
        Assert.NotNull(await ImageUpload.ValidateAsync(CreateFile("a.gif", "image/gif", PngHeader)));
    }

    [Fact]
    public async Task Rejects_content_type_that_does_not_match_extension()
    {
        Assert.NotNull(await ImageUpload.ValidateAsync(CreateFile("a.png", "image/jpeg", PngHeader)));
    }

    [Fact]
    public async Task Rejects_file_whose_bytes_do_not_match_extension()
    {
        Assert.NotNull(await ImageUpload.ValidateAsync(CreateFile("a.png", "image/png", JpegHeader)));
    }

    [Fact]
    public async Task Rejects_riff_file_that_is_not_webp()
    {
        var wav = new byte[] { 0x52, 0x49, 0x46, 0x46, 0x24, 0x00, 0x00, 0x00, 0x57, 0x41, 0x56, 0x45 };

        Assert.NotNull(await ImageUpload.ValidateAsync(CreateFile("a.webp", "image/webp", wav)));
    }

    [Fact]
    public async Task Rejects_file_larger_than_limit()
    {
        var file = new FormFile(new MemoryStream(PngHeader), 0, ImageUpload.MaxBytes + 1, "file", "a.png")
        {
            Headers = new HeaderDictionary(),
            ContentType = "image/png"
        };

        Assert.NotNull(await ImageUpload.ValidateAsync(file));
    }
}

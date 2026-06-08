using System.Text.Json.Serialization;

namespace MerhumAPI.Services.Groq;

public class GroqMessage
{
    [JsonPropertyName("role")]
    public string Role { get; set; } = string.Empty;

    [JsonPropertyName("content")]
    public string Content { get; set; } = string.Empty;
}

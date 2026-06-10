using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using MerhumAPI.Services.Groq;

namespace MerhumAPI.Services.Chat;

public class GroqService : IGroqService
{
    private const string Fallback = "Žao mi je, trenutno ne mogu odgovoriti na Vaš upit. Molimo pokušajte ponovo za nekoliko trenutaka.";

    private readonly HttpClient _httpClient;
    private readonly IConfiguration _configuration;
    private readonly ILogger<GroqService> _logger;

    public GroqService(HttpClient httpClient, IConfiguration configuration, ILogger<GroqService> logger)
    {
        _httpClient = httpClient;
        _configuration = configuration;
        _logger = logger;
    }

    public async Task<string> GetChatResponseAsync(string systemPrompt, string userMessage, List<GroqMessage>? conversationHistory = null)
    {
        var apiKey = _configuration["Groq:ApiKey"];
        var apiUrl = _configuration["Groq:ApiUrl"];
        var model = _configuration["Groq:Model"] ?? "llama-3.3-70b-versatile";
        var temperature = double.TryParse(_configuration["Groq:Temperature"], out var t) ? t : 0.7;
        var maxTokens = int.TryParse(_configuration["Groq:MaxTokens"], out var mt) ? mt : 1024;

        if (string.IsNullOrWhiteSpace(apiKey) || string.IsNullOrWhiteSpace(apiUrl))
        {
            _logger.LogWarning("Groq API key or URL is not configured.");
            return Fallback;
        }

        var messages = new List<GroqMessage>
        {
            new() { Role = "system", Content = systemPrompt }
        };

        if (conversationHistory != null && conversationHistory.Count > 0)
        {
            messages.AddRange(conversationHistory);
        }

        messages.Add(new GroqMessage { Role = "user", Content = userMessage });

        var request = new GroqRequest
        {
            Model = model,
            Messages = messages,
            Temperature = temperature,
            MaxTokens = maxTokens
        };

        try
        {
            using var httpRequest = new HttpRequestMessage(HttpMethod.Post, apiUrl)
            {
                Content = JsonContent.Create(request)
            };
            httpRequest.Headers.Authorization = new AuthenticationHeaderValue("Bearer", apiKey);

            using var cts = new CancellationTokenSource(TimeSpan.FromSeconds(30));
            var httpResponse = await _httpClient.SendAsync(httpRequest, cts.Token);

            if (!httpResponse.IsSuccessStatusCode)
            {
                var body = await httpResponse.Content.ReadAsStringAsync(cts.Token);
                _logger.LogWarning("Groq API returned non-success status {Status}. Body: {Body}", httpResponse.StatusCode, body);
                return Fallback;
            }

            var response = await httpResponse.Content.ReadFromJsonAsync<GroqResponse>(cancellationToken: cts.Token);
            var content = response?.Choices.FirstOrDefault()?.Message?.Content;
            return string.IsNullOrWhiteSpace(content) ? Fallback : content;
        }
        catch (TaskCanceledException ex)
        {
            _logger.LogWarning(ex, "Groq API request timed out.");
            return Fallback;
        }
        catch (HttpRequestException ex)
        {
            _logger.LogWarning(ex, "Groq API HTTP request failed.");
            return Fallback;
        }
        catch (JsonException ex)
        {
            _logger.LogWarning(ex, "Failed to deserialize Groq API response.");
            return Fallback;
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Unexpected error while calling Groq API.");
            return Fallback;
        }
    }
}

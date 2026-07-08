using System.Globalization;
using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;

namespace MerhumAPI.Services.Payment;

public class PayPalService : IPayPalService
{
    private const string SandboxUrl = "https://api-m.sandbox.paypal.com";
    private const string LiveUrl = "https://api-m.paypal.com";

    private readonly HttpClient _httpClient;
    private readonly IConfiguration _configuration;
    private readonly ILogger<PayPalService> _logger;

    public PayPalService(HttpClient httpClient, IConfiguration configuration, ILogger<PayPalService> logger)
    {
        _httpClient = httpClient;
        _configuration = configuration;
        _logger = logger;
    }

    private string BaseUrl =>
        string.Equals(_configuration["PayPal:Mode"], "live", StringComparison.OrdinalIgnoreCase) ? LiveUrl : SandboxUrl;

    public async Task<string> GetAccessTokenAsync()
    {
        var clientId = _configuration["PayPal:ClientId"];
        var clientSecret = _configuration["PayPal:ClientSecret"];

        if (string.IsNullOrWhiteSpace(clientId) || string.IsNullOrWhiteSpace(clientSecret))
        {
            _logger.LogError("PayPal credentials are not configured.");
            throw new InvalidOperationException("Plaćanje trenutno nije dostupno. Molimo pokušajte kasnije.");
        }

        var basic = Convert.ToBase64String(Encoding.UTF8.GetBytes($"{clientId}:{clientSecret}"));

        using var request = new HttpRequestMessage(HttpMethod.Post, $"{BaseUrl}/v1/oauth2/token")
        {
            Content = new FormUrlEncodedContent(new[]
            {
                new KeyValuePair<string, string>("grant_type", "client_credentials")
            })
        };
        request.Headers.Authorization = new AuthenticationHeaderValue("Basic", basic);

        var response = await _httpClient.SendAsync(request);
        var body = await response.Content.ReadAsStringAsync();

        if (!response.IsSuccessStatusCode)
        {
            _logger.LogError("PayPal token request failed with status {Status}. Body: {Body}", response.StatusCode, body);
            throw new InvalidOperationException("Plaćanje trenutno nije dostupno. Molimo pokušajte kasnije.");
        }

        using var doc = JsonDocument.Parse(body);
        return doc.RootElement.GetProperty("access_token").GetString()
            ?? throw new InvalidOperationException("Plaćanje trenutno nije dostupno. Molimo pokušajte kasnije.");
    }

    public async Task<(string orderId, string approvalUrl)> CreateOrderAsync(decimal amount, string currency)
    {
        var token = await GetAccessTokenAsync();

        var payload = new
        {
            intent = "CAPTURE",
            purchase_units = new[]
            {
                new
                {
                    amount = new
                    {
                        currency_code = currency,
                        value = amount.ToString("0.00", CultureInfo.InvariantCulture)
                    }
                }
            },
            application_context = new
            {
                return_url = _configuration["PayPal:ReturnUrl"],
                cancel_url = _configuration["PayPal:CancelUrl"]
            }
        };

        using var request = new HttpRequestMessage(HttpMethod.Post, $"{BaseUrl}/v2/checkout/orders")
        {
            Content = new StringContent(JsonSerializer.Serialize(payload), Encoding.UTF8, "application/json")
        };
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);

        var response = await _httpClient.SendAsync(request);
        var body = await response.Content.ReadAsStringAsync();

        if (!response.IsSuccessStatusCode)
        {
            _logger.LogError("PayPal create order failed with status {Status}. Body: {Body}", response.StatusCode, body);
            throw new InvalidOperationException("Greška pri kreiranju plaćanja. Molimo pokušajte ponovo.");
        }

        using var doc = JsonDocument.Parse(body);
        var root = doc.RootElement;

        var orderId = root.GetProperty("id").GetString() ?? string.Empty;
        var approvalUrl = string.Empty;

        if (root.TryGetProperty("links", out var links))
        {
            foreach (var link in links.EnumerateArray())
            {
                if (link.TryGetProperty("rel", out var rel) && rel.GetString() == "approve")
                {
                    approvalUrl = link.GetProperty("href").GetString() ?? string.Empty;
                    break;
                }
            }
        }

        if (string.IsNullOrWhiteSpace(orderId) || string.IsNullOrWhiteSpace(approvalUrl))
        {
            _logger.LogError("PayPal create order response missing id or approval link. Body: {Body}", body);
            throw new InvalidOperationException("Greška pri kreiranju plaćanja. Molimo pokušajte ponovo.");
        }

        return (orderId, approvalUrl);
    }

    public async Task<(bool success, string captureId)> CaptureOrderAsync(string paypalOrderId)
    {
        var token = await GetAccessTokenAsync();

        using var request = new HttpRequestMessage(HttpMethod.Post, $"{BaseUrl}/v2/checkout/orders/{paypalOrderId}/capture")
        {
            Content = new StringContent("{}", Encoding.UTF8, "application/json")
        };
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);

        var response = await _httpClient.SendAsync(request);
        var body = await response.Content.ReadAsStringAsync();

        if (!response.IsSuccessStatusCode)
        {
            _logger.LogError("PayPal capture failed for order {OrderId} with status {Status}. Body: {Body}", paypalOrderId, response.StatusCode, body);
            return (false, string.Empty);
        }

        using var doc = JsonDocument.Parse(body);
        var root = doc.RootElement;

        var status = root.TryGetProperty("status", out var s) ? s.GetString() : null;
        if (!string.Equals(status, "COMPLETED", StringComparison.OrdinalIgnoreCase))
        {
            _logger.LogWarning("PayPal capture for order {OrderId} returned status {Status}.", paypalOrderId, status);
            return (false, string.Empty);
        }

        var captureId = root
            .GetProperty("purchase_units")[0]
            .GetProperty("payments")
            .GetProperty("captures")[0]
            .GetProperty("id")
            .GetString() ?? string.Empty;

        return (true, captureId);
    }

    public async Task<(bool success, string refundId)> RefundCaptureAsync(string captureId, decimal amount, string currency)
    {
        var token = await GetAccessTokenAsync();

        var payload = new
        {
            amount = new
            {
                value = amount.ToString("0.00", CultureInfo.InvariantCulture),
                currency_code = currency
            }
        };

        using var request = new HttpRequestMessage(HttpMethod.Post, $"{BaseUrl}/v2/payments/captures/{captureId}/refund")
        {
            Content = new StringContent(JsonSerializer.Serialize(payload), Encoding.UTF8, "application/json")
        };
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);

        var response = await _httpClient.SendAsync(request);
        var body = await response.Content.ReadAsStringAsync();

        if (!response.IsSuccessStatusCode)
        {
            _logger.LogError("PayPal refund failed for capture {CaptureId} with status {Status}. Body: {Body}", captureId, response.StatusCode, body);
            return (false, string.Empty);
        }

        using var doc = JsonDocument.Parse(body);
        var root = doc.RootElement;

        var status = root.TryGetProperty("status", out var s) ? s.GetString() : null;
        if (!string.Equals(status, "COMPLETED", StringComparison.OrdinalIgnoreCase) &&
            !string.Equals(status, "PENDING", StringComparison.OrdinalIgnoreCase))
        {
            _logger.LogWarning("PayPal refund for capture {CaptureId} returned status {Status}.", captureId, status);
            return (false, string.Empty);
        }

        var refundId = root.TryGetProperty("id", out var idProp) ? idProp.GetString() ?? string.Empty : string.Empty;
        return (true, refundId);
    }
}

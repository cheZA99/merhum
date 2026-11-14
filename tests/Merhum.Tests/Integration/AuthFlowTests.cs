using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using MassTransit.Testing;
using MerhumContracts;

namespace Merhum.Tests.Integration;

[Collection(ApiCollection.Name)]
[Trait("Category", "Integration")]
public class AuthFlowTests
{
    private readonly MerhumApiFactory _factory;

    public AuthFlowTests(MerhumApiFactory factory)
    {
        _factory = factory;
    }

    private static object NewRegistration(string username) => new
    {
        Username = username,
        FirstName = "Test",
        LastName = "Korisnik",
        Email = $"{username}@example.com",
        Password = "test1234"
    };

    [Fact]
    public async Task Registered_user_can_log_in_and_receives_a_token()
    {
        var client = _factory.CreateClient();
        var username = $"user{Guid.NewGuid():N}"[..20];

        var register = await client.PostAsJsonAsync("/api/auth/register", NewRegistration(username));
        Assert.Equal(HttpStatusCode.OK, register.StatusCode);

        var login = await client.PostAsJsonAsync("/api/auth/login", new { Username = username, Password = "test1234" });
        Assert.Equal(HttpStatusCode.OK, login.StatusCode);

        var body = await login.Content.ReadFromJsonAsync<JsonElement>();
        Assert.False(string.IsNullOrEmpty(body.GetProperty("token").GetString()));
        Assert.Equal("Porodica", body.GetProperty("role").GetString());
    }

    [Fact]
    public async Task Registering_a_taken_username_returns_conflict()
    {
        var client = _factory.CreateClient();
        var username = $"dupe{Guid.NewGuid():N}"[..20];

        await client.PostAsJsonAsync("/api/auth/register", NewRegistration(username));
        var second = await client.PostAsJsonAsync("/api/auth/register", NewRegistration(username));

        Assert.Equal(HttpStatusCode.Conflict, second.StatusCode);
    }

    [Fact]
    public async Task Forgot_password_publishes_reset_message_for_existing_user()
    {
        var client = _factory.CreateClient();
        var harness = _factory.Services.GetTestHarness();
        var username = $"reset{Guid.NewGuid():N}"[..20];
        var email = $"{username}@example.com";

        await client.PostAsJsonAsync("/api/auth/register", NewRegistration(username));
        var response = await client.PostAsJsonAsync("/api/auth/forgot-password", new { Email = email });

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.True(await harness.Published.Any<PasswordResetRequestedMessage>(x => x.Context.Message.Email == email));
    }
}

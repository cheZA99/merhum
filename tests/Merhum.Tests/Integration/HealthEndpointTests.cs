using System.Net;

namespace Merhum.Tests.Integration;

[Collection(ApiCollection.Name)]
[Trait("Category", "Integration")]
public class HealthEndpointTests
{
    private readonly MerhumApiFactory _factory;

    public HealthEndpointTests(MerhumApiFactory factory)
    {
        _factory = factory;
    }

    [Fact]
    public async Task Health_reports_healthy_when_database_and_bus_are_up()
    {
        var client = _factory.CreateClient();

        var response = await client.GetAsync("/health");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.Equal("Healthy", await response.Content.ReadAsStringAsync());
    }
}

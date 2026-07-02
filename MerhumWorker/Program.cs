using MassTransit;
using MerhumWorker.Consumers;
using MerhumWorker.Services;

// load secrets from the nearest .env for local runs; in Docker these come from compose env vars
for (var envDir = new DirectoryInfo(Directory.GetCurrentDirectory()); envDir != null; envDir = envDir.Parent)
{
    var envFile = Path.Combine(envDir.FullName, ".env");
    if (File.Exists(envFile))
    {
        DotNetEnv.Env.Load(envFile);
        break;
    }
}

var builder = Host.CreateApplicationBuilder(args);

builder.Services.AddSingleton<IEmailService, EmailService>();

builder.Services.AddMassTransit(x =>
{
    x.AddConsumer<FuneralRegisteredConsumer>();
    x.AddConsumer<AppointmentConfirmedConsumer>();
    x.AddConsumer<ImamNotificationConsumer>();
    x.AddConsumer<ServiceOrderedConsumer>();
    x.AddConsumer<ObituaryCreatedConsumer>();
    x.AddConsumer<AnniversaryReminderConsumer>();
    x.AddConsumer<PaymentCompletedConsumer>();

    x.UsingRabbitMq((ctx, cfg) =>
    {
        var host = builder.Configuration["RabbitMQ:Host"] ?? "rabbitmq";
        var port = ushort.Parse(builder.Configuration["RabbitMQ:Port"] ?? "5672");
        var username = builder.Configuration["RabbitMQ:Username"] ?? "guest";
        var password = builder.Configuration["RabbitMQ:Password"] ?? "guest";

        cfg.Host(host, port, "/", h =>
        {
            h.Username(username);
            h.Password(password);
        });

        cfg.ReceiveEndpoint("merhum.prijavljen", e =>
        {
            e.ConfigureConsumer<FuneralRegisteredConsumer>(ctx);
            e.UseMessageRetry(r => r.Interval(3, TimeSpan.FromSeconds(5)));
        });

        cfg.ReceiveEndpoint("merhum.termin.potvrden", e =>
        {
            e.ConfigureConsumer<AppointmentConfirmedConsumer>(ctx);
            e.UseMessageRetry(r => r.Interval(3, TimeSpan.FromSeconds(5)));
        });

        cfg.ReceiveEndpoint("merhum.imam.obavjestenje", e =>
        {
            e.ConfigureConsumer<ImamNotificationConsumer>(ctx);
            e.UseMessageRetry(r => r.Interval(3, TimeSpan.FromSeconds(5)));
        });

        cfg.ReceiveEndpoint("merhum.usluga.narucena", e =>
        {
            e.ConfigureConsumer<ServiceOrderedConsumer>(ctx);
            e.UseMessageRetry(r => r.Interval(3, TimeSpan.FromSeconds(5)));
        });

        cfg.ReceiveEndpoint("merhum.smrtovnica.kreirana", e =>
        {
            e.ConfigureConsumer<ObituaryCreatedConsumer>(ctx);
            e.UseMessageRetry(r => r.Interval(3, TimeSpan.FromSeconds(5)));
        });

        cfg.ReceiveEndpoint("merhum.godisnjica", e =>
        {
            e.ConfigureConsumer<AnniversaryReminderConsumer>(ctx);
            e.UseMessageRetry(r => r.Interval(3, TimeSpan.FromSeconds(5)));
        });

        cfg.ReceiveEndpoint("merhum.placanje.izvrseno", e =>
        {
            e.ConfigureConsumer<PaymentCompletedConsumer>(ctx);
            e.UseMessageRetry(r => r.Interval(3, TimeSpan.FromSeconds(5)));
        });
    });
});

builder.Logging.AddConsole();
builder.Logging.SetMinimumLevel(LogLevel.Information);

var host = builder.Build();
await host.RunAsync();

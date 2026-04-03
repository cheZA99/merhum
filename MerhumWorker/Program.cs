using MassTransit;
using MerhumWorker.Consumers;
using MerhumWorker.Messages;
using MerhumWorker.Services;

var builder = Host.CreateApplicationBuilder(args);

// Email Service
builder.Services.AddSingleton<EmailService>();

// MassTransit / RabbitMQ
builder.Services.AddMassTransit(x =>
{
    x.AddConsumer<FuneralRegisteredConsumer>();
    x.AddConsumer<AppointmentConfirmedConsumer>();
    x.AddConsumer<ImamNotificationConsumer>();
    x.AddConsumer<ObituaryCreatedConsumer>();
    x.AddConsumer<AnniversaryReminderConsumer>();

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
    });
});

var host = builder.Build();
host.Run();

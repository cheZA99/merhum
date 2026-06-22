using MassTransit;
using MerhumAPI.Data;
using MerhumAPI.Middleware;
using MerhumAPI.Models;
using MerhumAPI.Services;
using MerhumAPI.Services.Chat;
using MerhumAPI.Services.MachineLearning;
using MerhumAPI.Services.Payment;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using System.Text;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddDbContext<ApplicationDbContext>(options =>
    options.UseSqlServer(
	   builder.Configuration.GetConnectionString("DefaultConnection"),
	   sql => sql.EnableRetryOnFailure(
		  maxRetryCount: 5,
		  maxRetryDelay: TimeSpan.FromSeconds(10),
		  errorNumbersToAdd: null)));

builder.Services.AddIdentity<ApplicationUser, IdentityRole>(options =>
{
	options.Password.RequiredLength = 4;
	options.Password.RequireDigit = false;
	options.Password.RequireNonAlphanumeric = false;
	options.Password.RequireUppercase = false;
	options.Password.RequireLowercase = false;
})
.AddEntityFrameworkStores<ApplicationDbContext>()
.AddDefaultTokenProviders();

var jwtKey = builder.Configuration["JWT:Key"]
    ?? throw new InvalidOperationException("JWT:Key is missing from configuration.");

builder.Services.AddAuthentication(options =>
{
	options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
	options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
	options.TokenValidationParameters = new TokenValidationParameters
	{
		ValidateIssuer = true,
		ValidateAudience = true,
		ValidateLifetime = true,
		ValidateIssuerSigningKey = true,
		ValidIssuer = builder.Configuration["JWT:Issuer"],
		ValidAudience = builder.Configuration["JWT:Audience"],
		IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey))
	};
});

builder.Services.AddAuthorization(options =>
{
	options.AddPolicy("AdminOnly", policy => policy.RequireRole("Administrator"));
	options.AddPolicy("DesktopAccess", policy => policy.RequireRole("Administrator"));
	options.AddPolicy("MobileAccess", policy => policy.RequireRole("Porodica", "JavniKorisnik", "Administrator"));
	options.AddPolicy("ImamAccess", policy => policy.RequireRole("Imam", "Administrator"));
	options.AddPolicy("PogrebnoAccess", policy => policy.RequireRole("PogrebnoPreduzeće", "Administrator"));
});

builder.Services.AddMassTransit(x =>
{
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

		cfg.Message<MerhumAPI.Messages.FuneralRegisteredMessage>(m => m.SetEntityName("merhum.prijavljen"));
		cfg.Message<MerhumAPI.Messages.AppointmentConfirmedMessage>(m => m.SetEntityName("merhum.termin.potvrden"));
		cfg.Message<MerhumAPI.Messages.ServiceOrderedMessage>(m => m.SetEntityName("merhum.usluge.narudzba"));
		cfg.Message<MerhumAPI.Messages.ImamNotificationMessage>(m => m.SetEntityName("merhum.imam.obavjestenje"));
		cfg.Message<MerhumAPI.Messages.CommunityNotificationMessage>(m => m.SetEntityName("merhum.dzemat.notifikacija"));
		cfg.Message<MerhumAPI.Messages.ObituaryCreatedMessage>(m => m.SetEntityName("merhum.smrtovnica.kreirana"));
		cfg.Message<MerhumAPI.Messages.AnniversaryReminderMessage>(m => m.SetEntityName("merhum.godisnjica"));
		cfg.Message<MerhumAPI.Messages.PaymentCompletedMessage>(m => m.SetEntityName("merhum.placanje.izvrseno"));
	});
});

builder.Services.AddScoped<ITokenService, TokenService>();
builder.Services.AddScoped<IUserService, UserService>();
builder.Services.AddScoped<IObituaryService, ObituaryService>();
builder.Services.AddScoped<ICondolenceService, CondolenceService>();
builder.Services.AddScoped<IReportService, ReportService>();
builder.Services.AddScoped<IMosqueService, MosqueService>();
builder.Services.AddScoped<IImamService, ImamService>();
builder.Services.AddScoped<ICemeteryService, CemeteryService>();
builder.Services.AddScoped<IGraveSiteService, GraveSiteService>();
builder.Services.AddScoped<IFuneralHomeService, FuneralHomeService>();
builder.Services.AddScoped<IAppointmentService, AppointmentService>();
builder.Services.AddScoped<IServiceOrderService, ServiceOrderService>();

builder.Services.AddHttpClient<IGroqService, GroqService>();
builder.Services.AddScoped<IContextBuilderService, ContextBuilderService>();
builder.Services.AddScoped<IChatService, ChatService>();

builder.Services.AddHttpClient<IPayPalService, PayPalService>();
builder.Services.AddScoped<IPaymentService, PaymentService>();

builder.Services.AddScoped<ITrainingDataService, TrainingDataService>();
builder.Services.AddSingleton<ICemeteryPredictionService, CemeteryPredictionService>();

builder.Services.AddCors(options =>
{
	options.AddPolicy("FlutterPolicy", policy =>
	{
		policy
		   .AllowAnyOrigin()
		   .AllowAnyHeader()
		   .AllowAnyMethod();
	});
});

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
	c.SwaggerDoc("v1", new OpenApiInfo
	{
		Title = "Merhum API",
		Version = "v1",
		Description = "Funeral organization and digital obituary system"
	});

	c.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
	{
		Name = "Authorization",
		Type = SecuritySchemeType.Http,
		Scheme = "Bearer",
		BearerFormat = "JWT",
		In = ParameterLocation.Header,
		Description = "Enter: Bearer {your JWT token}"
	});

	c.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
	   {
		  new OpenApiSecurityScheme
		  {
			 Reference = new OpenApiReference { Type = ReferenceType.SecurityScheme, Id = "Bearer" }
		  },
		  Array.Empty<string>()
	   }
    });
});

builder.Services.AddDirectoryBrowser();

var app = builder.Build();

app.UseMiddleware<GlobalExceptionMiddleware>();
app.UseSwagger();
app.UseSwaggerUI(c =>
{
	c.SwaggerEndpoint("/swagger/v1/swagger.json", "Merhum API v1");
	c.RoutePrefix = "swagger";
});

app.MapGet("/", () => Results.Redirect("/swagger"));

app.UseStaticFiles();
app.UseCors("FlutterPolicy");
app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();

_ = Task.Run(async () =>
{
	await Task.Delay(3000);
	try
	{
		await SeedData.SeedAsync(app.Services);
	}
	catch (Exception ex)
	{
		var logger = app.Services.GetRequiredService<ILogger<Program>>();
		logger.LogError(ex, "An error occurred during database seeding.");
	}
});

app.Run();

using MassTransit;
using MerhumAPI.Data;
using MerhumAPI.Models;
using MerhumAPI.Services;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using System.Text;

var builder = WebApplication.CreateBuilder(args);

// Database
builder.Services.AddDbContext<ApplicationDbContext>(options =>
    options.UseSqlServer(
	   builder.Configuration.GetConnectionString("DefaultConnection"),
	   sql => sql.EnableRetryOnFailure(
		  maxRetryCount: 5,
		  maxRetryDelay: TimeSpan.FromSeconds(10),
		  errorNumbersToAdd: null)));

// Identity
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

// JWT Authentication
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

// Authorization Policies
builder.Services.AddAuthorization(options =>
{
	options.AddPolicy("AdminOnly", policy => policy.RequireRole("Administrator"));
	options.AddPolicy("DesktopAccess", policy => policy.RequireRole("Administrator"));
	options.AddPolicy("MobileAccess", policy => policy.RequireRole("Porodica", "JavniKorisnik", "Administrator"));
	options.AddPolicy("ImamAccess", policy => policy.RequireRole("Imam", "Administrator"));
	options.AddPolicy("PogrebnoAccess", policy => policy.RequireRole("PogrebnoPreduzeće", "Administrator"));
});

// MassTransit / RabbitMQ
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
	});
});

// Application Services
builder.Services.AddScoped<ITokenService, TokenService>();
builder.Services.AddScoped<IObituaryService, ObituaryService>();
builder.Services.AddScoped<IReportService, ReportService>();

// CORS
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

// Controllers & Swagger
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

// Static Files
builder.Services.AddDirectoryBrowser();

var app = builder.Build();

// Middleware
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

// Seed Data
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

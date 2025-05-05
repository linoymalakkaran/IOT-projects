// WAT.IoT.Api/Program.cs
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using System.Text;
using WAT.IoT.Core.Interfaces;
using WAT.IoT.Devices.Configuration;
using WAT.IoT.Devices.Services;
using WAT.IoT.Integration.Configuration;
using WAT.IoT.Integration.Services;
using WAT.IoT.Processing.Configuration;
using WAT.IoT.Processing.Services;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddApplicationInsightsTelemetry();
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// Configure options
builder.Services.Configure<IoTHubOptions>(builder.Configuration.GetSection("IoTHub"));
builder.Services.Configure<ProcessingOptions>(builder.Configuration.GetSection("Processing"));
builder.Services.Configure<ScadaIntegrationOptions>(builder.Configuration.GetSection("ScadaIntegration"));

// Register HTTP clients
builder.Services.AddHttpClient();

// Register core services
builder.Services.AddSingleton<IDeviceRegistry, DeviceRegistryService>();
builder.Services.AddSingleton<IDeviceCommunication, DeviceCommunicationService>();
builder.Services.AddSingleton<ITelemetryProcessor, TelemetryProcessorService>();
builder.Services.AddSingleton<IAlertManager, AlertManagerService>();
builder.Services.AddSingleton<IScadaIntegration, ScadaIntegrationService>();
builder.Services.AddSingleton<IFloodManagement, FloodManagementService>();

// Configure JWT authentication
var jwtSettings = builder.Configuration.GetSection("JwtSettings");
var key = Encoding.ASCII.GetBytes(jwtSettings["Secret"] ?? "DefaultSecretKeyThatShouldBeReplacedInProduction");

builder.Services.AddAuthentication(x =>
{
    x.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    x.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(x =>
{
    x.RequireHttpsMetadata = false;
    x.SaveToken = true;
    x.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuerSigningKey = true,
        IssuerSigningKey = new SymmetricSecurityKey(key),
        ValidateIssuer = true,
        ValidIssuer = jwtSettings["Issuer"],
        ValidateAudience = true,
        ValidAudience = jwtSettings["Audience"],
        ValidateLifetime = true,
        ClockSkew = TimeSpan.Zero
    };
});

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

// Initialize telemetry processor
var telemetryProcessor = app.Services.GetRequiredService<ITelemetryProcessor>();
if (telemetryProcessor is TelemetryProcessorService processorService)
{
    Task.Run(async () =>
    {
        try
        {
            await processorService.StartProcessingAsync();
        }
        catch (Exception ex)
        {
            var logger = app.Services.GetRequiredService<ILogger<Program>>();
            logger.LogError(ex, "Error starting telemetry processor");
        }
    });
}

app.Run();

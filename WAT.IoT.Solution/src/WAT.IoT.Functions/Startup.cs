// WAT.IoT.Functions/Startup.cs
using Microsoft.Azure.Functions.Extensions.DependencyInjection;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using WAT.IoT.Core.Interfaces;
using WAT.IoT.Devices.Configuration;
using WAT.IoT.Devices.Services;
using WAT.IoT.Integration.Configuration;
using WAT.IoT.Integration.Services;
using WAT.IoT.Processing.Configuration;
using WAT.IoT.Processing.Services;

[assembly: FunctionsStartup(typeof(WAT.IoT.Functions.Startup))]

namespace WAT.IoT.Functions
{
    public class Startup : FunctionsStartup
    {
        public override void Configure(IFunctionsHostBuilder builder)
        {
            // Get configuration
            var configuration = builder.GetContext().Configuration;

            // Configure options
            builder.Services.Configure<IoTHubOptions>(options =>
            {
                options.ConnectionString = configuration["IoTHubConnectionString"];
                options.DpsIdScope = configuration["DpsIdScope"];
                options.DpsGlobalEndpoint = configuration["DpsGlobalEndpoint"];
                options.DefaultTimeoutSeconds = int.Parse(configuration["DefaultTimeoutSeconds"] ?? "30");
                options.EnableTwinSync = bool.Parse(configuration["EnableTwinSync"] ?? "true");
                options.EnableLogging = bool.Parse(configuration["EnableLogging"] ?? "true");
                options.RetryCount = int.Parse(configuration["RetryCount"] ?? "3");
                options.RetryIntervalMilliseconds = int.Parse(configuration["RetryIntervalMilliseconds"] ?? "1000");
            });

            builder.Services.Configure<ProcessingOptions>(options =>
            {
                options.EventHubConnectionString = configuration["EventHubConnection"];
                options.EventHubName = configuration["EventHubName"] ?? "telemetry";
                options.ConsumerGroup = configuration["ConsumerGroup"] ?? "";
                options.CosmosDbConnectionString = configuration["CosmosDbConnection"];
                options.CosmosDbDatabaseName = configuration["CosmosDbName"];
                options.TelemetryContainerName = configuration["TelemetryContainer"];
                options.EventsContainerName = configuration["EventsContainer"];
                options.WaterQualityContainerName = configuration["WaterQualityContainer"];
                options.HighPressureThreshold = double.Parse(configuration["AlertThresholds:HighPressure"] ?? "100.0");
                options.LowPressureThreshold = double.Parse(configuration["AlertThresholds:LowPressure"] ?? "10.0");
                options.WaterQualityThreshold = double.Parse(configuration["AlertThresholds:WaterQuality"] ?? "50.0");
                options.BatteryLowThreshold = double.Parse(configuration["AlertThresholds:BatteryLow"] ?? "15.0");
            });

            builder.Services.Configure<ScadaIntegrationOptions>(options =>
            {
                options.ScadaApiBaseUrl = configuration["ScadaIntegration:ScadaApiBaseUrl"];
                options.AlertEndpoint = configuration["ScadaIntegration:AlertEndpoint"];
                options.ApiKey = configuration["ScadaIntegration:ApiKey"];
            });

            // Register HTTP clients
            builder.Services.AddHttpClient();

            // Register services
            builder.Services.AddSingleton<IDeviceRegistry, DeviceRegistryService>();
            builder.Services.AddSingleton<IDeviceCommunication, DeviceCommunicationService>();
            builder.Services.AddSingleton<IAlertManager, AlertManagerService>();
            builder.Services.AddSingleton<IScadaIntegration, ScadaIntegrationService>();
        }
    }
}

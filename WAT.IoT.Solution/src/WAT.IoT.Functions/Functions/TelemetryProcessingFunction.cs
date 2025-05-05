// WAT.IoT.Functions/Functions/TelemetryProcessingFunction.cs
using Microsoft.Azure.WebJobs;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using System.Collections.Generic;
using System.Text;
using WAT.IoT.Core.Models;

namespace WAT.IoT.Functions.Functions
{
    public class TelemetryProcessingFunction
    {
        private readonly IConfiguration _configuration;
        private readonly ILogger<TelemetryProcessingFunction> _logger;
        private readonly HttpClient _httpClient;
        
        public TelemetryProcessingFunction(
            IConfiguration configuration,
            ILogger<TelemetryProcessingFunction> logger,
            IHttpClientFactory httpClientFactory)
        {
            _configuration = configuration;
            _logger = logger;
            _httpClient = httpClientFactory.CreateClient();
        }

        [FunctionName("ProcessTelemetry")]
        public async Task Run(
            [EventHubTrigger("telemetry", Connection = "EventHubConnection")] string[] events,
            [CosmosDB(
                databaseName: "%CosmosDbName%",
                containerName: "%TelemetryContainer%",
                Connection = "CosmosDbConnection")] IAsyncCollector<TelemetryReading> telemetryCollector,
            ILogger log)
        {
            log.LogInformation($"Processing {events.Length} telemetry events");

            foreach (var eventData in events)
            {
                try
                {
                    // Deserialize the telemetry event
                    var telemetry = JsonConvert.DeserializeObject<TelemetryReading>(eventData);
                    
                    if (telemetry == null)
                    {
                        log.LogWarning("Failed to deserialize telemetry event");
                        continue;
                    }
                    
                    // Save to Cosmos DB
                    await telemetryCollector.AddAsync(telemetry);
                    
                    // Check for alerts
                    await CheckForAlertsAsync(telemetry, log);
                    
                    log.LogInformation($"Processed telemetry for device {telemetry.DeviceId}");
                }
                catch (Exception ex)
                {
                    log.LogError(ex, "Error processing telemetry event: {EventData}", eventData);
                }
            }
        }

        private async Task CheckForAlertsAsync(TelemetryReading telemetry, ILogger log)
        {
            var alerts = new List<Alert>();
            
            // Water level alerts
            if (telemetry.WaterLevelStatus == WaterLevelStatus.High || telemetry.WaterLevelStatus == WaterLevelStatus.Critical)
            {
                alerts.Add(new Alert
                {
                    DeviceId = telemetry.DeviceId,
                    Type = AlertType.HighWaterLevel,
                    Severity = telemetry.WaterLevelStatus == WaterLevelStatus.Critical ? 
                        AlertSeverity.Emergency : AlertSeverity.Warning,
                    Message = $"High water level detected: {telemetry.WaterLevelStatus}",
                    Timestamp = DateTime.UtcNow
                });
            }
            else if (telemetry.WaterLevelStatus == WaterLevelStatus.Low)
            {
                alerts.Add(new Alert
                {
                    DeviceId = telemetry.DeviceId,
                    Type = AlertType.LowWaterLevel,
                    Severity = AlertSeverity.Warning,
                    Message = "Low water level detected",
                    Timestamp = DateTime.UtcNow
                });
            }
            
            // Water pressure alerts
            double highPressureThreshold = double.Parse(_configuration["AlertThresholds:HighPressure"] ?? "100.0");
            double lowPressureThreshold = double.Parse(_configuration["AlertThresholds:LowPressure"] ?? "10.0");
            
            if (telemetry.WaterPressure > highPressureThreshold)
            {
                alerts.Add(new Alert
                {
                    DeviceId = telemetry.DeviceId,
                    Type = AlertType.HighPressure,
                    Severity = AlertSeverity.Warning,
                    Message = $"High water pressure detected: {telemetry.WaterPressure} Pa",
                    Timestamp = DateTime.UtcNow
                });
            }
            else if (telemetry.WaterPressure < lowPressureThreshold)
            {
                alerts.Add(new Alert
                {
                    DeviceId = telemetry.DeviceId,
                    Type = AlertType.LowPressure,
                    Severity = AlertSeverity.Warning,
                    Message = $"Low water pressure detected: {telemetry.WaterPressure} Pa",
                    Timestamp = DateTime.UtcNow
                });
            }
            
            // Water quality alerts
            double waterQualityThreshold = double.Parse(_configuration["AlertThresholds:WaterQuality"] ?? "50.0");
            
            if (telemetry.WaterQuality < waterQualityThreshold)
            {
                alerts.Add(new Alert
                {
                    DeviceId = telemetry.DeviceId,
                    Type = AlertType.PoorWaterQuality,
                    Severity = telemetry.WaterQuality < waterQualityThreshold / 2 ? 
                        AlertSeverity.Critical : AlertSeverity.Warning,
                    Message = $"Poor water quality detected: {telemetry.WaterQuality}",
                    Timestamp = DateTime.UtcNow
                });
            }
            
            // Battery level alerts
            double batteryLowThreshold = double.Parse(_configuration["AlertThresholds:BatteryLow"] ?? "15.0");
            
            if (telemetry.BatteryLevel < batteryLowThreshold)
            {
                alerts.Add(new Alert
                {
                    DeviceId = telemetry.DeviceId,
                    Type = AlertType.BatteryLow,
                    Severity = telemetry.BatteryLevel < batteryLowThreshold / 2 ? 
                        AlertSeverity.Critical : AlertSeverity.Warning,
                    Message = $"Low battery level detected: {telemetry.BatteryLevel}%",
                    Timestamp = DateTime.UtcNow
                });
            }
            
            // Send alerts to event hub
            if (alerts.Count > 0)
            {
                string alertsApiUrl = _configuration["AlertsApiUrl"];
                string apiKey = _configuration["ApiKey"];
                
                if (!string.IsNullOrEmpty(alertsApiUrl) && !string.IsNullOrEmpty(apiKey))
                {
                    try
                    {
                        _httpClient.DefaultRequestHeaders.Clear();
                        _httpClient.DefaultRequestHeaders.Add("X-API-Key", apiKey);
                        
                        foreach (var alert in alerts)
                        {
                            var content = new StringContent(
                                JsonConvert.SerializeObject(alert),
                                Encoding.UTF8,
                                "application/json");
                            
                            var response = await _httpClient.PostAsync(alertsApiUrl, content);
                            
                            if (!response.IsSuccessStatusCode)
                            {
                                log.LogWarning($"Failed to send alert to API. Status: {response.StatusCode}");
                            }
                        }
                    }
                    catch (Exception ex)
                    {
                        log.LogError(ex, "Error sending alerts to API");
                    }
                }
                else
                {
                    log.LogWarning("Alert API URL or API Key not configured");
                }
            }
        }
    }
}

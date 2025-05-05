// WAT.IoT.Functions/Functions/DeviceConnectionMonitorFunction.cs
using Microsoft.Azure.Devices;
using Microsoft.Azure.WebJobs;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using System.Collections.Generic;
using System.Net.Http.Headers;
using System.Text;
using WAT.IoT.Core.Interfaces;
using WAT.IoT.Core.Models;

namespace WAT.IoT.Functions.Functions
{
    public class DeviceConnectionMonitorFunction
    {
        private readonly IConfiguration _configuration;
        private readonly HttpClient _httpClient;
        private readonly RegistryManager _registryManager;
        
        public DeviceConnectionMonitorFunction(
            IConfiguration configuration,
            IHttpClientFactory httpClientFactory)
        {
            _configuration = configuration;
            _httpClient = httpClientFactory.CreateClient();
            
            string iotHubConnectionString = _configuration["IoTHubConnectionString"];
            _registryManager = RegistryManager.CreateFromConnectionString(iotHubConnectionString);
        }

        [FunctionName("MonitorDeviceConnections")]
        public async Task Run(
            [TimerTrigger("0 */15 * * * *")] TimerInfo myTimer, // Run every 15 minutes
            ILogger log)
        {
            log.LogInformation($"Device Connection Monitor function executed at: {DateTime.Now}");
            
            try
            {
                // Get all devices
                var query = _registryManager.CreateQuery("SELECT * FROM devices", 100);
                var devices = new List<DeviceInfo>();
                
                while (query.HasMoreResults)
                {
                    var page = await query.GetNextAsTwinAsync();
                    foreach (var twin in page)
                    {
                        var device = new DeviceInfo
                        {
                            DeviceId = twin.DeviceId,
                            LastActivityTime = twin.LastActivityTime ?? DateTime.MinValue
                        };
                        
                        devices.Add(device);
                    }
                }
                
                log.LogInformation($"Checking connection status for {devices.Count} devices");
                
                // Check for devices that haven't communicated recently (1 hour)
                var inactiveThreshold = DateTime.UtcNow.AddHours(-1);
                var inactiveDevices = devices.Where(d => d.LastActivityTime < inactiveThreshold).ToList();
                
                if (inactiveDevices.Any())
                {
                    log.LogWarning($"Found {inactiveDevices.Count} inactive devices");
                    
                    // Create alerts for inactive devices
                    foreach (var device in inactiveDevices)
                    {
                        var alert = new Alert
                        {
                            DeviceId = device.DeviceId,
                            Type = AlertType.DeviceOffline,
                            Severity = AlertSeverity.Warning,
                            Message = $"Device has been offline since {device.LastActivityTime}",
                            Timestamp = DateTime.UtcNow
                        };
                        
                        await SendAlertAsync(alert, log);
                    }
                }
                else
                {
                    log.LogInformation("All devices are active");
                }
            }
            catch (Exception ex)
            {
                log.LogError(ex, "Error monitoring device connections");
            }
        }

        private async Task SendAlertAsync(Alert alert, ILogger log)
        {
            try
            {
                string alertsApiUrl = _configuration["AlertsApiUrl"];
                string apiKey = _configuration["ApiKey"];
                
                if (string.IsNullOrEmpty(alertsApiUrl) || string.IsNullOrEmpty(apiKey))
                {
                    log.LogWarning("Alerts API URL or API Key not configured");
                    return;
                }
                
                _httpClient.DefaultRequestHeaders.Clear();
                _httpClient.DefaultRequestHeaders.Accept.Add(new MediaTypeWithQualityHeaderValue("application/json"));
                _httpClient.DefaultRequestHeaders.Add("X-API-Key", apiKey);
                
                var content = new StringContent(
                    JsonConvert.SerializeObject(alert),
                    Encoding.UTF8,
                    "application/json");
                
                var response = await _httpClient.PostAsync(alertsApiUrl, content);
                
                if (response.IsSuccessStatusCode)
                {
                    log.LogInformation($"Successfully sent offline device alert for {alert.DeviceId}");
                }
                else
                {
                    log.LogWarning($"Failed to send offline device alert. Status: {response.StatusCode}");
                }
            }
            catch (Exception ex)
            {
                log.LogError(ex, $"Error sending offline device alert for {alert.DeviceId}");
            }
        }
    }
}

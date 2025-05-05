// WAT.IoT.Functions/Functions/AlertProcessingFunction.cs
using Microsoft.Azure.Cosmos;
using Microsoft.Azure.WebJobs;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using System.Net.Http.Headers;
using System.Text;
using WAT.IoT.Core.Models;

namespace WAT.IoT.Functions.Functions
{
    public class AlertProcessingFunction
    {
        private readonly IConfiguration _configuration;
        private readonly HttpClient _httpClient;
        
        public AlertProcessingFunction(
            IConfiguration configuration,
            IHttpClientFactory httpClientFactory)
        {
            _configuration = configuration;
            _httpClient = httpClientFactory.CreateClient();
        }

        [FunctionName("ProcessAlert")]
        public async Task Run(
            [CosmosDBTrigger(
                databaseName: "%CosmosDbName%",
                containerName: "%EventsContainer%",
                Connection = "CosmosDbConnection",
                LeaseContainerName = "leases",
                CreateLeaseContainerIfNotExists = true)] IReadOnlyList<Alert> alerts,
            ILogger log)
        {
            if (alerts == null || alerts.Count == 0)
            {
                return;
            }
            
            log.LogInformation($"Processing {alerts.Count} alerts");
            
            string scadaApiUrl = _configuration["ScadaIntegration:ScadaApiBaseUrl"];
            string alertEndpoint = _configuration["ScadaIntegration:AlertEndpoint"];
            string apiKey = _configuration["ScadaIntegration:ApiKey"];
            
            if (string.IsNullOrEmpty(scadaApiUrl) || string.IsNullOrEmpty(alertEndpoint))
            {
                log.LogWarning("SCADA API URL or Alert Endpoint not configured");
                return;
            }
            
            _httpClient.DefaultRequestHeaders.Clear();
            _httpClient.DefaultRequestHeaders.Accept.Add(new MediaTypeWithQualityHeaderValue("application/json"));
            
            if (!string.IsNullOrEmpty(apiKey))
            {
                _httpClient.DefaultRequestHeaders.Add("X-API-Key", apiKey);
            }
            
            foreach (var alert in alerts)
            {
                try
                {
                    // Only process new, unacknowledged alerts
                    if (alert.Acknowledged)
                    {
                        continue;
                    }
                    
                    log.LogInformation($"Sending alert {alert.AlertId} to SCADA system");
                    
                    var content = new StringContent(
                        JsonConvert.SerializeObject(alert),
                        Encoding.UTF8,
                        "application/json");
                    
                    string url = $"{scadaApiUrl.TrimEnd('/')}/{alertEndpoint.TrimStart('/')}";
                    var response = await _httpClient.PostAsync(url, content);
                    
                    if (response.IsSuccessStatusCode)
                    {
                        log.LogInformation($"Successfully sent alert {alert.AlertId} to SCADA system");
                    }
                    else
                    {
                        log.LogWarning($"Failed to send alert {alert.AlertId} to SCADA system. Status: {response.StatusCode}");
                    }
                    
                    // For critical or emergency alerts, also send SMS/Email notification
                    if (alert.Severity == AlertSeverity.Critical || alert.Severity == AlertSeverity.Emergency)
                    {
                        await SendNotificationAsync(alert, log);
                    }
                }
                catch (Exception ex)
                {
                    log.LogError(ex, $"Error processing alert {alert.AlertId}");
                }
            }
        }

        private async Task SendNotificationAsync(Alert alert, ILogger log)
        {
            try
            {
                string notificationApiUrl = _configuration["NotificationApiUrl"];
                
                if (string.IsNullOrEmpty(notificationApiUrl))
                {
                    log.LogWarning("Notification API URL not configured");
                    return;
                }
                
                var notification = new
                {
                    Recipients = new[] { "operations@wattreatment.com" },
                    Subject = $"WAT ALERT: {alert.Severity} - {alert.Type}",
                    Message = $"Device: {alert.DeviceId}\nType: {alert.Type}\nSeverity: {alert.Severity}\nTime: {alert.Timestamp}\nMessage: {alert.Message}",
                    AlertId = alert.AlertId
                };
                
                var content = new StringContent(
                    JsonConvert.SerializeObject(notification),
                    Encoding.UTF8,
                    "application/json");
                
                var response = await _httpClient.PostAsync(notificationApiUrl, content);
                
                if (response.IsSuccessStatusCode)
                {
                    log.LogInformation($"Successfully sent notification for alert {alert.AlertId}");
                }
                else
                {
                    log.LogWarning($"Failed to send notification for alert {alert.AlertId}. Status: {response.StatusCode}");
                }
            }
            catch (Exception ex)
            {
                log.LogError(ex, $"Error sending notification for alert {alert.AlertId}");
            }
        }
    }
}

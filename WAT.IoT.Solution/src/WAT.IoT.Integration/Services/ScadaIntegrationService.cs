// WAT.IoT.Integration/Services/ScadaIntegrationService.cs
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Newtonsoft.Json;
using System.Net.Http.Headers;
using System.Text;
using WAT.IoT.Core.Interfaces;
using WAT.IoT.Core.Models;
using WAT.IoT.Integration.Configuration;

namespace WAT.IoT.Integration.Services
{
    public class ScadaIntegrationService : IScadaIntegration
    {
        private readonly ILogger<ScadaIntegrationService> _logger;
        private readonly ScadaIntegrationOptions _options;
        private readonly HttpClient _httpClient;
        private readonly Dictionary<string, Queue<ValveCommand>> _mockCommandQueue = new Dictionary<string, Queue<ValveCommand>>();

        public ScadaIntegrationService(
            IOptions<ScadaIntegrationOptions> options,
            ILogger<ScadaIntegrationService> logger,
            IHttpClientFactory httpClientFactory)
        {
            _logger = logger;
            _options = options.Value;
            _httpClient = httpClientFactory.CreateClient("ScadaApi");
            
            // Configure the HTTP client
            _httpClient.BaseAddress = new Uri(_options.ScadaApiBaseUrl);
            _httpClient.Timeout = TimeSpan.FromSeconds(_options.TimeoutSeconds);
            _httpClient.DefaultRequestHeaders.Accept.Clear();
            _httpClient.DefaultRequestHeaders.Accept.Add(new MediaTypeWithQualityHeaderValue("application/json"));
            
            if (!string.IsNullOrEmpty(_options.ApiKey))
            {
                _httpClient.DefaultRequestHeaders.Add("X-API-Key", _options.ApiKey);
            }
        }

        public async Task SendTelemetryToScadaAsync(TelemetryReading telemetry)
        {
            try
            {
                if (_options.EnableMock)
                {
                    _logger.LogInformation("MOCK: Sending telemetry to SCADA for device {DeviceId}", telemetry.DeviceId);
                    return;
                }

                _logger.LogInformation("Sending telemetry to SCADA for device {DeviceId}", telemetry.DeviceId);
                
                var content = new StringContent(
                    JsonConvert.SerializeObject(telemetry), 
                    Encoding.UTF8, 
                    "application/json");
                
                var response = await ExecuteWithRetryAsync(() => 
                    _httpClient.PostAsync(_options.TelemetryEndpoint, content));
                
                if (response.IsSuccessStatusCode)
                {
                    _logger.LogInformation("Successfully sent telemetry to SCADA for device {DeviceId}", telemetry.DeviceId);
                }
                else
                {
                    _logger.LogWarning("Failed to send telemetry to SCADA. Status: {StatusCode}", response.StatusCode);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error sending telemetry to SCADA for device {DeviceId}", telemetry.DeviceId);
            }
        }

        public async Task SendAlertToScadaAsync(Alert alert)
        {
            try
            {
                if (_options.EnableMock)
                {
                    _logger.LogInformation("MOCK: Sending alert to SCADA: {AlertType} for device {DeviceId}", 
                        alert.Type, alert.DeviceId);
                    return;
                }

                _logger.LogInformation("Sending alert to SCADA: {AlertType} for device {DeviceId}", 
                    alert.Type, alert.DeviceId);
                
                var content = new StringContent(
                    JsonConvert.SerializeObject(alert), 
                    Encoding.UTF8, 
                    "application/json");
                
                var response = await ExecuteWithRetryAsync(() => 
                    _httpClient.PostAsync(_options.AlertEndpoint, content));
                
                if (response.IsSuccessStatusCode)
                {
                    _logger.LogInformation("Successfully sent alert to SCADA: {AlertType} for device {DeviceId}", 
                        alert.Type, alert.DeviceId);
                }
                else
                {
                    _logger.LogWarning("Failed to send alert to SCADA. Status: {StatusCode}", response.StatusCode);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error sending alert to SCADA: {AlertType} for device {DeviceId}", 
                    alert.Type, alert.DeviceId);
            }
        }

        public async Task NotifyValveOperationAsync(string deviceId, ValveAction action)
        {
            try
            {
                if (_options.EnableMock)
                {
                    _logger.LogInformation("MOCK: Notifying SCADA of valve operation: {Action} for device {DeviceId}", 
                        action, deviceId);
                    return;
                }

                _logger.LogInformation("Notifying SCADA of valve operation: {Action} for device {DeviceId}", 
                    action, deviceId);
                
                var payload = new
                {
                    DeviceId = deviceId,
                    Action = action.ToString(),
                    Timestamp = DateTime.UtcNow
                };
                
                var content = new StringContent(
                    JsonConvert.SerializeObject(payload), 
                    Encoding.UTF8, 
                    "application/json");
                
                var response = await ExecuteWithRetryAsync(() => 
                    _httpClient.PostAsync(_options.ValveOperationEndpoint, content));
                
                if (response.IsSuccessStatusCode)
                {
                    _logger.LogInformation("Successfully notified SCADA of valve operation: {Action} for device {DeviceId}", 
                        action, deviceId);
                }
                else
                {
                    _logger.LogWarning("Failed to notify SCADA of valve operation. Status: {StatusCode}", response.StatusCode);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error notifying SCADA of valve operation: {Action} for device {DeviceId}", 
                    action, deviceId);
            }
        }

        public async Task NotifyFloodEventAsync(FloodEvent floodEvent)
        {
            try
            {
                if (_options.EnableMock)
                {
                    _logger.LogInformation("MOCK: Notifying SCADA of flood event: {EventId} at {Location}", 
                        floodEvent.EventId, floodEvent.Location);
                    return;
                }

                _logger.LogInformation("Notifying SCADA of flood event: {EventId} at {Location}", 
                    floodEvent.EventId, floodEvent.Location);
                
                var content = new StringContent(
                    JsonConvert.SerializeObject(floodEvent), 
                    Encoding.UTF8, 
                    "application/json");
                
                var response = await ExecuteWithRetryAsync(() => 
                    _httpClient.PostAsync(_options.FloodEventEndpoint, content));
                
                if (response.IsSuccessStatusCode)
                {
                    _logger.LogInformation("Successfully notified SCADA of flood event: {EventId}", floodEvent.EventId);
                }
                else
                {
                    _logger.LogWarning("Failed to notify SCADA of flood event. Status: {StatusCode}", response.StatusCode);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error notifying SCADA of flood event: {EventId}", floodEvent.EventId);
            }
        }

        public async Task<bool> ReceiveCommandFromScadaAsync(ValveCommand command)
        {
            try
            {
                _logger.LogInformation("Received command from SCADA: {Action} for device {DeviceId}", 
                    command.Action, command.DeviceId);
                
                // In a mock scenario, store the command in the queue for later retrieval
                if (_options.EnableMock)
                {
                    if (!_mockCommandQueue.TryGetValue(command.DeviceId, out var queue))
                    {
                        queue = new Queue<ValveCommand>();
                        _mockCommandQueue[command.DeviceId] = queue;
                    }
                    
                    queue.Enqueue(command);
                    return true;
                }
                
                // In a real implementation, this would validate the command
                // and potentially update a database or trigger an event
                
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error receiving command from SCADA: {Action} for device {DeviceId}", 
                    command.Action, command.DeviceId);
                return false;
            }
        }

        // For mock implementation - allows retrieving pending commands
        public ValveCommand? GetNextPendingCommand(string deviceId)
        {
            if (!_options.EnableMock || !_mockCommandQueue.TryGetValue(deviceId, out var queue) || queue.Count == 0)
            {
                return null;
            }
            
            return queue.Dequeue();
        }

        private async Task<HttpResponseMessage> ExecuteWithRetryAsync(Func<Task<HttpResponseMessage>> action)
        {
            int retryCount = 0;
            HttpResponseMessage? response = null;
            
            while (retryCount < _options.RetryCount)
            {
                try
                {
                    response = await action();
                    
                    if (response.IsSuccessStatusCode)
                    {
                        return response;
                    }
                    
                    retryCount++;
                    
                    if (retryCount < _options.RetryCount)
                    {
                        int delay = (int)Math.Pow(2, retryCount) * 1000; // Exponential backoff
                        _logger.LogWarning("Retrying request in {DelayMs}ms. Attempt {Attempt}/{MaxAttempts}", 
                            delay, retryCount + 1, _options.RetryCount);
                        await Task.Delay(delay);
                    }
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Error executing HTTP request. Attempt {Attempt}/{MaxAttempts}", 
                        retryCount + 1, _options.RetryCount);
                    
                    retryCount++;
                    
                    if (retryCount < _options.RetryCount)
                    {
                        int delay = (int)Math.Pow(2, retryCount) * 1000; // Exponential backoff
                        await Task.Delay(delay);
                    }
                    else
                    {
                        throw; // Rethrow if we've exhausted retries
                    }
                }
            }
            
            return response ?? new HttpResponseMessage(System.Net.HttpStatusCode.InternalServerError);
        }
    }
}

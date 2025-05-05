// WAT.IoT.Devices/Services/DeviceCommunicationService.cs
using Microsoft.Azure.Devices;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Newtonsoft.Json;
using System.Text;
using WAT.IoT.Core.Interfaces;
using WAT.IoT.Core.Models;
using WAT.IoT.Devices.Configuration;

namespace WAT.IoT.Devices.Services
{
    public class DeviceCommunicationService : IDeviceCommunication
    {
        private readonly ServiceClient _serviceClient;
        private readonly ILogger<DeviceCommunicationService> _logger;
        private readonly IoTHubOptions _options;
        private readonly RegistryManager _registryManager;
        private readonly Dictionary<string, DeviceConnectionStatus> _connectionStatusCache = new Dictionary<string, DeviceConnectionStatus>();
        private readonly Dictionary<string, TelemetryReading> _latestTelemetryCache = new Dictionary<string, TelemetryReading>();

        public DeviceCommunicationService(IOptions<IoTHubOptions> options, ILogger<DeviceCommunicationService> logger)
        {
            _options = options.Value;
            _logger = logger;
            _serviceClient = ServiceClient.CreateFromConnectionString(_options.ConnectionString);
            _registryManager = RegistryManager.CreateFromConnectionString(_options.ConnectionString);
        }

        public async Task<bool> SendCommandAsync(string deviceId, ValveCommand command)
        {
            try
            {
                var methodInvocation = new CloudToDeviceMethod("ValveOperation")
                {
                    ResponseTimeout = TimeSpan.FromSeconds(_options.DefaultTimeoutSeconds)
                };

                string commandJson = JsonConvert.SerializeObject(command);
                methodInvocation.SetPayloadJson(commandJson);

                _logger.LogInformation("Sending valve command to device {DeviceId}: {Action}", 
                    deviceId, command.Action);

                var result = await _serviceClient.InvokeDeviceMethodAsync(deviceId, methodInvocation);
                
                if (result.Status == 200)
                {
                    _logger.LogInformation("Command sent successfully to device {DeviceId}", deviceId);
                    return true;
                }
                else
                {
                    _logger.LogWarning("Failed to send command to device {DeviceId}. Status: {Status}", 
                        deviceId, result.Status);
                    return false;
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error sending command to device {DeviceId}", deviceId);
                return false;
            }
        }

        public async Task<bool> SendCommandBatchAsync(IEnumerable<ValveCommand> commands)
        {
            bool allSucceeded = true;
            foreach (var command in commands)
            {
                bool success = await SendCommandAsync(command.DeviceId, command);
                if (!success)
                {
                    allSucceeded = false;
                    _logger.LogWarning("Failed to send command to device {DeviceId}", command.DeviceId);
                }
            }
            return allSucceeded;
        }

        public async Task<TelemetryReading?> GetLatestTelemetryAsync(string deviceId)
        {
            try
            {
                if (_latestTelemetryCache.TryGetValue(deviceId, out TelemetryReading? cachedReading))
                {
                    // If cache is less than 5 minutes old, return it
                    if (DateTime.UtcNow.Subtract(cachedReading.Timestamp).TotalMinutes < 5)
                    {
                        return cachedReading;
                    }
                }

                // Send a direct method to get latest telemetry
                var methodInvocation = new CloudToDeviceMethod("GetLatestTelemetry")
                {
                    ResponseTimeout = TimeSpan.FromSeconds(_options.DefaultTimeoutSeconds)
                };

                var result = await _serviceClient.InvokeDeviceMethodAsync(deviceId, methodInvocation);
                
                if (result.Status == 200)
                {
                    var telemetry = JsonConvert.DeserializeObject<TelemetryReading>(result.GetPayloadAsJson());
                    if (telemetry != null)
                    {
                        _latestTelemetryCache[deviceId] = telemetry;
                        return telemetry;
                    }
                }
                
                _logger.LogWarning("Failed to get latest telemetry for device {DeviceId}", deviceId);
                return null;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting latest telemetry for device {DeviceId}", deviceId);
                return null;
            }
        }

        public async Task<bool> IsDeviceOnlineAsync(string deviceId)
        {
            var status = await GetConnectionStatusAsync(deviceId);
            return status == DeviceConnectionStatus.Online;
        }

        public async Task<DeviceConnectionStatus> GetConnectionStatusAsync(string deviceId)
        {
            try
            {
                if (_connectionStatusCache.TryGetValue(deviceId, out DeviceConnectionStatus cachedStatus))
                {
                    return cachedStatus;
                }

                var twin = await _registryManager.GetTwinAsync(deviceId);
                if (twin == null)
                {
                    _logger.LogWarning("Device {DeviceId} not found", deviceId);
                    return DeviceConnectionStatus.Unknown;
                }

                // Check connection state from reported properties
                if (twin.ConnectionState == Microsoft.Azure.Devices.Shared.ConnectionState.Connected)
                {
                    _connectionStatusCache[deviceId] = DeviceConnectionStatus.Online;
                    return DeviceConnectionStatus.Online;
                }
                else if (twin.ConnectionState == Microsoft.Azure.Devices.Shared.ConnectionState.Disconnected)
                {
                    _connectionStatusCache[deviceId] = DeviceConnectionStatus.Offline;
                    return DeviceConnectionStatus.Offline;
                }

                // If last activity time is recent (within 15 minutes), consider it online
                if (twin.LastActivityTime.HasValue && 
                    DateTime.UtcNow.Subtract(twin.LastActivityTime.Value).TotalMinutes < 15)
                {
                    _connectionStatusCache[deviceId] = DeviceConnectionStatus.Online;
                    return DeviceConnectionStatus.Online;
                }

                // Try sending a ping to check if device is responsive
                try
                {
                    var methodInvocation = new CloudToDeviceMethod("Ping")
                    {
                        ResponseTimeout = TimeSpan.FromSeconds(5) // Short timeout for ping
                    };

                    var result = await _serviceClient.InvokeDeviceMethodAsync(deviceId, methodInvocation);
                    if (result.Status == 200)
                    {
                        _connectionStatusCache[deviceId] = DeviceConnectionStatus.Online;
                        return DeviceConnectionStatus.Online;
                    }
                }
                catch
                {
                    // If ping fails, device is offline
                    _connectionStatusCache[deviceId] = DeviceConnectionStatus.Offline;
                    return DeviceConnectionStatus.Offline;
                }

                _connectionStatusCache[deviceId] = DeviceConnectionStatus.Unknown;
                return DeviceConnectionStatus.Unknown;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error checking connection status for device {DeviceId}", deviceId);
                return DeviceConnectionStatus.Unknown;
            }
        }

        public async Task UpdateConnectionStatusCacheAsync(string deviceId, DeviceConnectionStatus status)
        {
            _connectionStatusCache[deviceId] = status;
            await Task.CompletedTask;
        }

        public async Task UpdateTelemetryCacheAsync(TelemetryReading reading)
        {
            _latestTelemetryCache[reading.DeviceId] = reading;
            await Task.CompletedTask;
        }
    }
}

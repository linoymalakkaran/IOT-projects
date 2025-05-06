// WAT.IoT.Devices/Services/DeviceRegistryService.cs
using Microsoft.Azure.Devices;
using Microsoft.Azure.Devices.Shared;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using System.Collections.Concurrent;
using WAT.IoT.Core.Interfaces;
using WAT.IoT.Core.Models;
using WAT.IoT.Devices.Configuration;
using Newtonsoft.Json.Linq;
using System.Reflection;

namespace WAT.IoT.Devices.Services
{
    public class DeviceRegistryService : IDeviceRegistry
    {
        private readonly RegistryManager _registryManager;
        private readonly ILogger<DeviceRegistryService> _logger;
        private readonly IoTHubOptions _options;
        private readonly ConcurrentDictionary<string, DeviceInfo> _deviceCache = new ConcurrentDictionary<string, DeviceInfo>();

        public DeviceRegistryService(IOptions<IoTHubOptions> options, ILogger<DeviceRegistryService> logger)
        {
            _options = options.Value;
            _logger = logger;
            _registryManager = RegistryManager.CreateFromConnectionString(_options.ConnectionString);
        }

        public async Task<DeviceInfo> GetDeviceInfoAsync(string deviceId)
        {
            try
            {
                if (_deviceCache.TryGetValue(deviceId, out DeviceInfo? cachedDevice))
                {
                    return cachedDevice;
                }

                Device device = await _registryManager.GetDeviceAsync(deviceId);
                Twin twin = await _registryManager.GetTwinAsync(deviceId);

                if (device == null || twin == null)
                {
                    _logger.LogWarning("Device {DeviceId} not found", deviceId);
                    return new DeviceInfo { DeviceId = deviceId, IsActive = false };
                }

                var deviceInfo = MapToDeviceInfo(device, twin);
                _deviceCache[deviceId] = deviceInfo;
                return deviceInfo;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting device {DeviceId}", deviceId);
                throw;
            }
        }

        public async Task<IEnumerable<DeviceInfo>> GetAllDevicesAsync()
        {
            var devices = new List<DeviceInfo>();
            try
            {
                var query = _registryManager.CreateQuery("SELECT * FROM devices", 100);

                while (query.HasMoreResults)
                {
                    var page = await query.GetNextAsTwinAsync();
                    foreach (var twin in page)
                    {
                        var device = await _registryManager.GetDeviceAsync(twin.DeviceId);
                        var deviceInfo = MapToDeviceInfo(device, twin);
                        devices.Add(deviceInfo);
                        _deviceCache[twin.DeviceId] = deviceInfo;
                    }
                }

                return devices;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting all devices");
                throw;
            }
        }

        public async Task<IEnumerable<DeviceInfo>> GetDevicesByLocationAsync(string location)
        {
            var devices = new List<DeviceInfo>();
            try
            {
                // First check if we have devices for this location in cache
                var cachedDevicesForLocation = _deviceCache.Values
                    .Where(d => d.Location == location)
                    .ToList();

                // If we have a significant number of devices already cached, use them
                if (cachedDevicesForLocation.Count > 50) // Arbitrary threshold
                {
                    _logger.LogInformation("Retrieved {Count} devices for location {Location} from cache",
                        cachedDevicesForLocation.Count, location);
                    return cachedDevicesForLocation;
                }

                // Otherwise query IoT Hub
                _logger.LogInformation("Querying IoT Hub for devices in location {Location}", location);

                // Optimize query to only select necessary fields
                var query = _registryManager.CreateQuery(
                    $"SELECT deviceId, status, lastActivityTime, properties.reported.firmwareVersion, " +
                    $"tags.deviceType, tags.connectionType FROM devices WHERE tags.location = '{location}'",
                    100);

                while (query.HasMoreResults)
                {
                    var page = await query.GetNextAsTwinAsync();
                    foreach (var twin in page)
                    {
                        // Avoid redundant device queries by using a minimal Twin-only approach
                        var deviceInfo = new DeviceInfo
                        {
                            DeviceId = twin.DeviceId,
                            IsActive = true, // Default, will be updated below
                            Location = location, // We know this from the query
                            LastActivityTime = twin.LastActivityTime ?? DateTime.UtcNow
                        };

                        // Manually check status via device registry only when necessary
                        var device = await _registryManager.GetDeviceAsync(twin.DeviceId);
                        if (device != null)
                        {
                            deviceInfo.IsActive = device.Status == DeviceStatus.Enabled;
                        }

                        // Extract other properties - Use the safe Contains method for TwinCollection
                        if (twin.Tags.Contains("deviceType"))
                        {
                            deviceInfo.DeviceType = twin.Tags["deviceType"]?.ToString();
                        }

                        if (twin.Tags.Contains("connectionType"))
                        {
                            deviceInfo.ConnectionType = twin.Tags["connectionType"]?.ToString();
                        }

                        if (twin.Properties.Reported.Contains("firmwareVersion"))
                        {
                            deviceInfo.FirmwareVersion = twin.Properties.Reported["firmwareVersion"]?.ToString();
                        }

                        deviceInfo.Tags = new Dictionary<string, string>();
                        // Safe iteration through TwinCollection using dynamic iteration
                        ExtractTags(twin.Tags, deviceInfo.Tags);

                        devices.Add(deviceInfo);
                        _deviceCache[twin.DeviceId] = deviceInfo;
                    }
                }

                return devices;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting devices by location {Location}", location);
                throw;
            }
        }

        public async Task<bool> AddDeviceAsync(DeviceInfo device)
        {
            try
            {
                var azureDevice = new Device(device.DeviceId);
                azureDevice.Status = device.IsActive ? DeviceStatus.Enabled : DeviceStatus.Disabled;

                Device createdDevice = await _registryManager.AddDeviceAsync(azureDevice);

                var twin = new Twin(device.DeviceId);

                // Set tag values directly
                if (!string.IsNullOrEmpty(device.DeviceType))
                    twin.Tags["deviceType"] = device.DeviceType;

                if (!string.IsNullOrEmpty(device.Location))
                    twin.Tags["location"] = device.Location;

                if (!string.IsNullOrEmpty(device.ConnectionType))
                    twin.Tags["connectionType"] = device.ConnectionType;

                // Set reported properties
                if (!string.IsNullOrEmpty(device.FirmwareVersion))
                    twin.Properties.Reported["firmwareVersion"] = device.FirmwareVersion;

                // Add custom tags
                if (device.Tags != null)
                {
                    foreach (var tagEntry in device.Tags)
                    {
                        twin.Tags[tagEntry.Key] = tagEntry.Value;
                    }
                }

                await _registryManager.UpdateTwinAsync(device.DeviceId, twin, twin.ETag);

                _deviceCache[device.DeviceId] = device;
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error adding device {DeviceId}", device.DeviceId);
                return false;
            }
        }

        public async Task<bool> UpdateDeviceAsync(DeviceInfo device)
        {
            try
            {
                var existingDevice = await _registryManager.GetDeviceAsync(device.DeviceId);
                if (existingDevice == null)
                {
                    _logger.LogWarning("Device {DeviceId} not found for update", device.DeviceId);
                    return false;
                }

                existingDevice.Status = device.IsActive ? DeviceStatus.Enabled : DeviceStatus.Disabled;
                await _registryManager.UpdateDeviceAsync(existingDevice);

                var twin = await _registryManager.GetTwinAsync(device.DeviceId);

                // Update tag values
                twin.Tags["deviceType"] = device.DeviceType;
                twin.Tags["location"] = device.Location;
                twin.Tags["connectionType"] = device.ConnectionType;

                // Update custom tags
                if (device.Tags != null)
                {
                    foreach (var tag in device.Tags)
                    {
                        twin.Tags[tag.Key] = tag.Value;
                    }
                }

                await _registryManager.UpdateTwinAsync(device.DeviceId, twin, twin.ETag);

                _deviceCache[device.DeviceId] = device;
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating device {DeviceId}", device.DeviceId);
                return false;
            }
        }

        public async Task<bool> DeleteDeviceAsync(string deviceId)
        {
            try
            {
                await _registryManager.RemoveDeviceAsync(deviceId);
                _deviceCache.TryRemove(deviceId, out _);
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting device {DeviceId}", deviceId);
                return false;
            }
        }

        public async Task<bool> IsDeviceRegisteredAsync(string deviceId)
        {
            try
            {
                if (_deviceCache.TryGetValue(deviceId, out DeviceInfo? _))
                {
                    return true;
                }

                var device = await _registryManager.GetDeviceAsync(deviceId);
                return device != null;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error checking if device {DeviceId} is registered", deviceId);
                return false;
            }
        }

        // Helper method to extract tags from TwinCollection into a Dictionary
        private void ExtractTags(TwinCollection twinCollection, Dictionary<string, string> targetDictionary)
        {
            if (twinCollection == null)
                return;

            // TwinCollection doesn't implement IDictionary directly, but we can use reflection to iterate its elements
            // Convert to JObject for easier iteration as an alternative approach
            var jsonObject = JObject.Parse(twinCollection.ToJson());

            foreach (var property in jsonObject.Properties())
            {
                string tagKey = property.Name;
                if (tagKey != "deviceType" && tagKey != "location" && tagKey != "connectionType")
                {
                    string tagValue = property.Value?.ToString() ?? string.Empty;
                    targetDictionary[tagKey] = tagValue;
                }
            }
        }

        private DeviceInfo MapToDeviceInfo(Device device, Twin twin)
        {
            var deviceInfo = new DeviceInfo
            {
                DeviceId = device.Id,
                IsActive = device.Status == DeviceStatus.Enabled,
                // Handle DateTime safely
                LastActivityTime = DateTime.UtcNow // Default value
            };

            // Safe handling of LastActivityTime
            if (device.LastActivityTime != null)
            {
                deviceInfo.LastActivityTime = device.LastActivityTime.Date;
            }

            // Use safe way to access tag values using string indexing
            if (twin.Tags.Contains("deviceType"))
            {
                deviceInfo.DeviceType = twin.Tags["deviceType"]?.ToString();
            }

            if (twin.Tags.Contains("location"))
            {
                deviceInfo.Location = twin.Tags["location"]?.ToString();
            }

            if (twin.Tags.Contains("connectionType"))
            {
                deviceInfo.ConnectionType = twin.Tags["connectionType"]?.ToString();
            }

            // Safe way to access reported properties
            if (twin.Properties.Reported.Contains("firmwareVersion"))
            {
                deviceInfo.FirmwareVersion = twin.Properties.Reported["firmwareVersion"]?.ToString();
            }

            // Initialize the Tags dictionary
            deviceInfo.Tags = new Dictionary<string, string>();

            // Use helper method to safely extract tags
            ExtractTags(twin.Tags, deviceInfo.Tags);

            return deviceInfo;
        }
    }
}
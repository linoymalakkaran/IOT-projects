// WAT.IoT.Devices/Services/DeviceRegistryService.cs
using Microsoft.Azure.Devices;
using Microsoft.Azure.Devices.Shared;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using System.Collections.Concurrent;
using WAT.IoT.Core.Interfaces;
using WAT.IoT.Core.Models;
using WAT.IoT.Devices.Configuration;

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
                var query = _registryManager.CreateQuery($"SELECT * FROM devices WHERE tags.location = '{location}'", 100);
                
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
                twin.Tags["deviceType"] = device.DeviceType;
                twin.Tags["location"] = device.Location;
                twin.Tags["connectionType"] = device.ConnectionType;
                twin.Properties.Reported["firmwareVersion"] = device.FirmwareVersion;
                
                foreach (var tag in device.Tags)
                {
                    twin.Tags[tag.Key] = tag.Value;
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
                twin.Tags["deviceType"] = device.DeviceType;
                twin.Tags["location"] = device.Location;
                twin.Tags["connectionType"] = device.ConnectionType;
                
                foreach (var tag in device.Tags)
                {
                   twin.Tags[tag.Key] = tag.Value;
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

        private DeviceInfo MapToDeviceInfo(Device device, Twin twin)
        {
            var deviceInfo = new DeviceInfo
            {
                DeviceId = device.Id,
                IsActive = device.Status == DeviceStatus.Enabled,
                LastActivityTime = device.LastActivityTime ?? DateTime.UtcNow
            };

            if (twin.Tags.Contains("deviceType"))
            {
                deviceInfo.DeviceType = twin.Tags["deviceType"];
            }

            if (twin.Tags.Contains("location"))
            {
                deviceInfo.Location = twin.Tags["location"];
            }

            if (twin.Tags.Contains("connectionType"))
            {
                deviceInfo.ConnectionType = twin.Tags["connectionType"];
            }

            if (twin.Properties.Reported.Contains("firmwareVersion"))
            {
                deviceInfo.FirmwareVersion = twin.Properties.Reported["firmwareVersion"];
            }

            foreach (var tag in twin.Tags)
            {
                if (tag.Key != "deviceType" && tag.Key != "location" && tag.Key != "connectionType")
                {
                    deviceInfo.Tags[tag.Key] = tag.Value;
                }
            }

            return deviceInfo;
        }
    }
}

// WAT.IoT.Api/Controllers/DevicesController.cs
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using WAT.IoT.Core.Interfaces;
using WAT.IoT.Core.Models;

namespace WAT.IoT.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class DevicesController : ControllerBase
    {
        private readonly IDeviceRegistry _deviceRegistry;
        private readonly IDeviceCommunication _deviceCommunication;
        private readonly ILogger<DevicesController> _logger;

        public DevicesController(
            IDeviceRegistry deviceRegistry,
            IDeviceCommunication deviceCommunication,
            ILogger<DevicesController> logger)
        {
            _deviceRegistry = deviceRegistry;
            _deviceCommunication = deviceCommunication;
            _logger = logger;
        }

        [HttpGet]
        public async Task<ActionResult<IEnumerable<DeviceInfo>>> GetAllDevices()
        {
            try
            {
                var devices = await _deviceRegistry.GetAllDevicesAsync();
                return Ok(devices);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting all devices");
                return StatusCode(500, "An error occurred while retrieving devices");
            }
        }

        [HttpGet("{deviceId}")]
        public async Task<ActionResult<DeviceInfo>> GetDevice(string deviceId)
        {
            try
            {
                var device = await _deviceRegistry.GetDeviceInfoAsync(deviceId);
                
                if (device == null || string.IsNullOrEmpty(device.DeviceId))
                {
                    return NotFound($"Device with ID {deviceId} not found");
                }
                
                return Ok(device);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting device {DeviceId}", deviceId);
                return StatusCode(500, $"An error occurred while retrieving device {deviceId}");
            }
        }

        [HttpGet("{deviceId}/telemetry")]
        public async Task<ActionResult<TelemetryReading>> GetDeviceTelemetry(string deviceId)
        {
            try
            {
                var telemetry = await _deviceCommunication.GetLatestTelemetryAsync(deviceId);
                
                if (telemetry == null)
                {
                    return NotFound($"No telemetry found for device {deviceId}");
                }
                
                return Ok(telemetry);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting telemetry for device {DeviceId}", deviceId);
                return StatusCode(500, $"An error occurred while retrieving telemetry for device {deviceId}");
            }
        }

        [HttpGet("location/{location}")]
        public async Task<ActionResult<IEnumerable<DeviceInfo>>> GetDevicesByLocation(string location)
        {
            try
            {
                var devices = await _deviceRegistry.GetDevicesByLocationAsync(location);
                return Ok(devices);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting devices by location {Location}", location);
                return StatusCode(500, $"An error occurred while retrieving devices for location {location}");
            }
        }

        [HttpPost]
        public async Task<ActionResult<DeviceInfo>> AddDevice(DeviceInfo device)
        {
            try
            {
                var isRegistered = await _deviceRegistry.IsDeviceRegisteredAsync(device.DeviceId);
                
                if (isRegistered)
                {
                    return Conflict($"Device with ID {device.DeviceId} already exists");
                }
                
                var result = await _deviceRegistry.AddDeviceAsync(device);
                
                if (!result)
                {
                    return BadRequest("Failed to add device");
                }
                
                return CreatedAtAction(nameof(GetDevice), new { deviceId = device.DeviceId }, device);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error adding device {DeviceId}", device.DeviceId);
                return StatusCode(500, $"An error occurred while adding device {device.DeviceId}");
            }
        }

        [HttpPut("{deviceId}")]
        public async Task<IActionResult> UpdateDevice(string deviceId, DeviceInfo device)
        {
            try
            {
                if (deviceId != device.DeviceId)
                {
                    return BadRequest("Device ID in the URL does not match the device ID in the request body");
                }
                
                var isRegistered = await _deviceRegistry.IsDeviceRegisteredAsync(deviceId);
                
                if (!isRegistered)
                {
                    return NotFound($"Device with ID {deviceId} not found");
                }
                
                var result = await _deviceRegistry.UpdateDeviceAsync(device);
                
                if (!result)
                {
                    return BadRequest("Failed to update device");
                }
                
                return NoContent();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating device {DeviceId}", deviceId);
                return StatusCode(500, $"An error occurred while updating device {deviceId}");
            }
        }

        [HttpDelete("{deviceId}")]
        public async Task<IActionResult> DeleteDevice(string deviceId)
        {
            try
            {
                var isRegistered = await _deviceRegistry.IsDeviceRegisteredAsync(deviceId);
                
                if (!isRegistered)
                {
                    return NotFound($"Device with ID {deviceId} not found");
                }
                
                var result = await _deviceRegistry.DeleteDeviceAsync(deviceId);
                
                if (!result)
                {
                    return BadRequest("Failed to delete device");
                }
                
                return NoContent();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting device {DeviceId}", deviceId);
                return StatusCode(500, $"An error occurred while deleting device {deviceId}");
            }
        }

        [HttpPost("{deviceId}/command")]
        public async Task<IActionResult> SendCommand(string deviceId, [FromBody] ValveCommand command)
        {
            try
            {
                if (deviceId != command.DeviceId)
                {
                    return BadRequest("Device ID in the URL does not match the device ID in the command");
                }
                
                var isRegistered = await _deviceRegistry.IsDeviceRegisteredAsync(deviceId);
                
                if (!isRegistered)
                {
                    return NotFound($"Device with ID {deviceId} not found");
                }
                
                var result = await _deviceCommunication.SendCommandAsync(deviceId, command);
                
                if (!result)
                {
                    return BadRequest("Failed to send command to device");
                }
                
                return Ok();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error sending command to device {DeviceId}", deviceId);
                return StatusCode(500, $"An error occurred while sending command to device {deviceId}");
            }
        }
    }
}

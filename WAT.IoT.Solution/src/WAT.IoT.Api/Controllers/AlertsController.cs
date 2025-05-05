// WAT.IoT.Api/Controllers/AlertsController.cs
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using WAT.IoT.Core.Interfaces;
using WAT.IoT.Core.Models;

namespace WAT.IoT.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class AlertsController : ControllerBase
    {
        private readonly IAlertManager _alertManager;
        private readonly ILogger<AlertsController> _logger;

        public AlertsController(
            IAlertManager alertManager,
            ILogger<AlertsController> logger)
        {
            _alertManager = alertManager;
            _logger = logger;
        }

        [HttpGet("active")]
        public async Task<ActionResult<IEnumerable<Alert>>> GetActiveAlerts()
        {
            try
            {
                var alerts = await _alertManager.GetActiveAlertsAsync();
                return Ok(alerts);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting active alerts");
                return StatusCode(500, "An error occurred while retrieving active alerts");
            }
        }

        [HttpGet("device/{deviceId}")]
        public async Task<ActionResult<IEnumerable<Alert>>> GetAlertsByDevice(string deviceId)
        {
            try
            {
                var alerts = await _alertManager.GetAlertsByDeviceAsync(deviceId);
                return Ok(alerts);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting alerts for device {DeviceId}", deviceId);
                return StatusCode(500, $"An error occurred while retrieving alerts for device {deviceId}");
            }
        }

        [HttpGet("type/{alertType}")]
        public async Task<ActionResult<IEnumerable<Alert>>> GetAlertsByType(AlertType alertType)
        {
            try
            {
                var alerts = await _alertManager.GetAlertsByTypeAsync(alertType);
                return Ok(alerts);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting alerts of type {AlertType}", alertType);
                return StatusCode(500, $"An error occurred while retrieving alerts of type {alertType}");
            }
        }

        [HttpGet("daterange")]
        public async Task<ActionResult<IEnumerable<Alert>>> GetAlertsByDateRange(
            [FromQuery] DateTime startTime, 
            [FromQuery] DateTime endTime)
        {
            try
            {
                if (startTime >= endTime)
                {
                    return BadRequest("Start time must be earlier than end time");
                }
                
                var alerts = await _alertManager.GetAlertsByDateRangeAsync(startTime, endTime);
                return Ok(alerts);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting alerts by date range");
                return StatusCode(500, "An error occurred while retrieving alerts by date range");
            }
        }

        [HttpPost("{alertId}/acknowledge")]
        public async Task<IActionResult> AcknowledgeAlert(string alertId, [FromBody] AcknowledgeRequest request)
        {
            try
            {
                var result = await _alertManager.AcknowledgeAlertAsync(alertId, request.AcknowledgedBy);
                
                if (!result)
                {
                    return NotFound($"Alert with ID {alertId} not found");
                }
                
                return Ok();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error acknowledging alert {AlertId}", alertId);
                return StatusCode(500, $"An error occurred while acknowledging alert {alertId}");
            }
        }

        public class AcknowledgeRequest
        {
            public string AcknowledgedBy { get; set; } = string.Empty;
        }
    }
}

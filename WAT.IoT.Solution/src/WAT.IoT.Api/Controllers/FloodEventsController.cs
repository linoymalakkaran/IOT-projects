// WAT.IoT.Api/Controllers/FloodEventsController.cs
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using WAT.IoT.Core.Interfaces;
using WAT.IoT.Core.Models;

namespace WAT.IoT.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class FloodEventsController : ControllerBase
    {
        private readonly IFloodManagement _floodManagement;
        private readonly ILogger<FloodEventsController> _logger;

        public FloodEventsController(
            IFloodManagement floodManagement,
            ILogger<FloodEventsController> logger)
        {
            _floodManagement = floodManagement;
            _logger = logger;
        }

        [HttpGet("active")]
        public async Task<ActionResult<IEnumerable<FloodEvent>>> GetActiveFloodEvents()
        {
            try
            {
                var events = await _floodManagement.GetActiveFloodEventsAsync();
                return Ok(events);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting active flood events");
                return StatusCode(500, "An error occurred while retrieving active flood events");
            }
        }

        [HttpGet("{eventId}")]
        public async Task<ActionResult<FloodEvent>> GetFloodEvent(string eventId)
        {
            try
            {
                var floodEvent = await _floodManagement.GetFloodEventByIdAsync(eventId);
                
                if (floodEvent == null)
                {
                    return NotFound($"Flood event with ID {eventId} not found");
                }
                
                return Ok(floodEvent);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting flood event {EventId}", eventId);
                return StatusCode(500, $"An error occurred while retrieving flood event {eventId}");
            }
        }

        [HttpGet("daterange")]
        public async Task<ActionResult<IEnumerable<FloodEvent>>> GetFloodEventsByDateRange(
            [FromQuery] DateTime startTime, 
            [FromQuery] DateTime endTime)
        {
            try
            {
                if (startTime >= endTime)
                {
                    return BadRequest("Start time must be earlier than end time");
                }
                
                var events = await _floodManagement.GetFloodEventsByDateRangeAsync(startTime, endTime);
                return Ok(events);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting flood events by date range");
                return StatusCode(500, "An error occurred while retrieving flood events by date range");
            }
        }

        [HttpPost]
        public async Task<ActionResult<string>> CreateFloodEvent(FloodEvent floodEvent)
        {
            try
            {
                var eventId = await _floodManagement.CreateFloodEventAsync(floodEvent);
                return CreatedAtAction(nameof(GetFloodEvent), new { eventId }, eventId);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating flood event");
                return StatusCode(500, "An error occurred while creating flood event");
            }
        }

        [HttpPut("{eventId}")]
        public async Task<IActionResult> UpdateFloodEvent(string eventId, FloodEvent floodEvent)
        {
            try
            {
                if (eventId != floodEvent.EventId)
                {
                    return BadRequest("Event ID in the URL does not match the event ID in the request body");
                }
                
                var result = await _floodManagement.UpdateFloodEventAsync(floodEvent);
                
                if (!result)
                {
                    return NotFound($"Flood event with ID {eventId} not found");
                }
                
                return NoContent();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating flood event {EventId}", eventId);
                return StatusCode(500, $"An error occurred while updating flood event {eventId}");
            }
        }

        [HttpPost("{eventId}/close")]
        public async Task<IActionResult> CloseFloodEvent(string eventId, [FromBody] CloseEventRequest request)
        {
            try
            {
                var result = await _floodManagement.CloseFloodEventAsync(eventId, request.EndTime);
                
                if (!result)
                {
                    return NotFound($"Flood event with ID {eventId} not found");
                }
                
                return Ok();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error closing flood event {EventId}", eventId);
                return StatusCode(500, $"An error occurred while closing flood event {eventId}");
            }
        }

        [HttpPost("{eventId}/report")]
        public async Task<IActionResult> SubmitRegulationReport(string eventId, [FromBody] ReportRequest request)
        {
            try
            {
                var result = await _floodManagement.SubmitRegulationReportAsync(eventId, request.SubmittedBy);
                
                if (!result)
                {
                    return NotFound($"Flood event with ID {eventId} not found");
                }
                
                return Ok();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error submitting regulation report for flood event {EventId}", eventId);
                return StatusCode(500, $"An error occurred while submitting regulation report for flood event {eventId}");
            }
        }

        public class CloseEventRequest
        {
            public DateTime EndTime { get; set; } = DateTime.UtcNow;
        }

        public class ReportRequest
        {
            public string SubmittedBy { get; set; } = string.Empty;
        }
    }
}

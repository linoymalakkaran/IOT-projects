// WAT.IoT.Integration/Services/FloodManagementService.cs
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using WAT.IoT.Core.Interfaces;
using WAT.IoT.Core.Models;
using WAT.IoT.Integration.Configuration;

namespace WAT.IoT.Integration.Services
{
    public class FloodManagementService : IFloodManagement
    {
        private readonly ILogger<FloodManagementService> _logger;
        private readonly ScadaIntegrationOptions _options;
        private readonly IScadaIntegration _scadaIntegration;
        private readonly List<FloodEvent> _activeFloodEvents = new List<FloodEvent>();
        private readonly List<FloodEvent> _historicalFloodEvents = new List<FloodEvent>();
        private readonly SemaphoreSlim _lock = new SemaphoreSlim(1, 1);

        public FloodManagementService(
            IOptions<ScadaIntegrationOptions> options,
            ILogger<FloodManagementService> logger,
            IScadaIntegration scadaIntegration)
        {
            _logger = logger;
            _options = options.Value;
            _scadaIntegration = scadaIntegration;
        }
		public async Task<string> CreateFloodEventAsync(FloodEvent floodEvent)
        {
            try
            {
                await _lock.WaitAsync();
                
                _logger.LogInformation("Creating flood event at location {Location}", floodEvent.Location);
                
                // Set a new ID if not provided
                if (string.IsNullOrEmpty(floodEvent.EventId))
                {
                    floodEvent.EventId = Guid.NewGuid().ToString();
                }
                
                // Ensure start time is set
                if (floodEvent.StartTime == default)
                {
                    floodEvent.StartTime = DateTime.UtcNow;
                }
                
                // Add to active events
                _activeFloodEvents.Add(floodEvent);
                
                // Notify SCADA system
                await _scadaIntegration.NotifyFloodEventAsync(floodEvent);
                
                _logger.LogInformation("Flood event created with ID: {EventId}", floodEvent.EventId);
                return floodEvent.EventId;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating flood event at location {Location}", floodEvent.Location);
                throw;
            }
            finally
            {
                _lock.Release();
            }
        }

        public async Task<bool> UpdateFloodEventAsync(FloodEvent floodEvent)
        {
            try
            {
                await _lock.WaitAsync();
                
                _logger.LogInformation("Updating flood event: {EventId}", floodEvent.EventId);
                
                // Find the event
                var existingEventIndex = _activeFloodEvents.FindIndex(e => e.EventId == floodEvent.EventId);
                
                if (existingEventIndex >= 0)
                {
                    // Update the active event
                    _activeFloodEvents[existingEventIndex] = floodEvent;
                    
                    // Notify SCADA system
                    await _scadaIntegration.NotifyFloodEventAsync(floodEvent);
                    
                    _logger.LogInformation("Flood event updated: {EventId}", floodEvent.EventId);
                    return true;
                }
                else
                {
                    // Check historical events
                    var historicalEventIndex = _historicalFloodEvents.FindIndex(e => e.EventId == floodEvent.EventId);
                    
                    if (historicalEventIndex >= 0)
                    {
                        // Update the historical event
                        _historicalFloodEvents[historicalEventIndex] = floodEvent;
                        
                        // Notify SCADA system
                        await _scadaIntegration.NotifyFloodEventAsync(floodEvent);
                        
                        _logger.LogInformation("Historical flood event updated: {EventId}", floodEvent.EventId);
                        return true;
                    }
                }
                
                _logger.LogWarning("Flood event not found for update: {EventId}", floodEvent.EventId);
                return false;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating flood event: {EventId}", floodEvent.EventId);
                return false;
            }
            finally
            {
                _lock.Release();
            }
        }

        public async Task<bool> CloseFloodEventAsync(string eventId, DateTime endTime)
        {
            try
            {
                await _lock.WaitAsync();
                
                _logger.LogInformation("Closing flood event: {EventId}", eventId);
                
                // Find the event
                var existingEvent = _activeFloodEvents.FirstOrDefault(e => e.EventId == eventId);
                
                if (existingEvent != null)
                {
                    // Update end time
                    existingEvent.EndTime = endTime;
                    
                    // Move to historical events
                    _activeFloodEvents.Remove(existingEvent);
                    _historicalFloodEvents.Add(existingEvent);
                    
                    // Notify SCADA system
                    await _scadaIntegration.NotifyFloodEventAsync(existingEvent);
                    
                    _logger.LogInformation("Flood event closed: {EventId}", eventId);
                    return true;
                }
                
                _logger.LogWarning("Flood event not found for closing: {EventId}", eventId);
                return false;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error closing flood event: {EventId}", eventId);
                return false;
            }
            finally
            {
                _lock.Release();
            }
        }

        public async Task<bool> SubmitRegulationReportAsync(string eventId, string submittedBy)
        {
            try
            {
                await _lock.WaitAsync();
                
                _logger.LogInformation("Submitting regulation report for flood event: {EventId}", eventId);
                
                // Find the event (check both active and historical)
                var floodEvent = _activeFloodEvents.FirstOrDefault(e => e.EventId == eventId) ??
                                _historicalFloodEvents.FirstOrDefault(e => e.EventId == eventId);
                
                if (floodEvent != null)
                {
                    // Update report information
                    floodEvent.HasRegulationReport = true;
                    floodEvent.RegulationReportTime = DateTime.UtcNow;
                    floodEvent.ReportSubmittedBy = submittedBy;
                    
                    // Notify SCADA system
                    await _scadaIntegration.NotifyFloodEventAsync(floodEvent);
                    
                    _logger.LogInformation("Regulation report submitted for flood event: {EventId}", eventId);
                    return true;
                }
                
                _logger.LogWarning("Flood event not found for regulation report: {EventId}", eventId);
                return false;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error submitting regulation report for flood event: {EventId}", eventId);
                return false;
            }
            finally
            {
                _lock.Release();
            }
        }

        public async Task<IEnumerable<FloodEvent>> GetActiveFloodEventsAsync()
        {
            try
            {
                await _lock.WaitAsync();
                return _activeFloodEvents.ToList();
            }
            finally
            {
                _lock.Release();
            }
        }

        public async Task<IEnumerable<FloodEvent>> GetFloodEventsByDateRangeAsync(DateTime startTime, DateTime endTime)
        {
            try
            {
                await _lock.WaitAsync();
                
                var result = new List<FloodEvent>();
                
                // Check active events
                result.AddRange(_activeFloodEvents.Where(e => e.StartTime >= startTime && 
                    (e.EndTime == null || e.EndTime <= endTime)));
                
                // Check historical events
                result.AddRange(_historicalFloodEvents.Where(e => e.StartTime >= startTime && 
                    (e.EndTime == null || e.EndTime <= endTime)));
                
                return result;
            }
            finally
            {
                _lock.Release();
            }
        }

        public async Task<FloodEvent?> GetFloodEventByIdAsync(string eventId)
        {
            try
            {
                await _lock.WaitAsync();
                
                // Check active events first
                var activeEvent = _activeFloodEvents.FirstOrDefault(e => e.EventId == eventId);
                
                if (activeEvent != null)
                {
                    return activeEvent;
                }
                
                // Check historical events
                return _historicalFloodEvents.FirstOrDefault(e => e.EventId == eventId);
            }
            finally
            {
                _lock.Release();
            }
        }
    }
}

// WAT.IoT.Processing/Services/TelemetryProcessorService.cs
using Azure.Messaging.EventHubs;
using Azure.Messaging.EventHubs.Consumer;
using Azure.Messaging.EventHubs.Processor;
using Azure.Storage.Blobs;
using Microsoft.Azure.Cosmos;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Newtonsoft.Json;
using System.Text;
using WAT.IoT.Core.Interfaces;
using WAT.IoT.Core.Models;
using WAT.IoT.Processing.Configuration;

namespace WAT.IoT.Processing.Services
{
    public class TelemetryProcessorService : ITelemetryProcessor, IAsyncDisposable
    {
        private readonly ILogger<TelemetryProcessorService> _logger;
        private readonly ProcessingOptions _options;
        private readonly CosmosClient _cosmosClient;
        private readonly Container _telemetryContainer;
        private readonly Container _waterQualityContainer;
        private readonly IAlertManager _alertManager;
        private readonly IDeviceCommunication _deviceCommunication;
        private readonly Dictionary<string, List<TelemetryReading>> _telemetryCache = new Dictionary<string, List<TelemetryReading>>();
        private readonly SemaphoreSlim _cacheLock = new SemaphoreSlim(1, 1);
        private EventProcessorClient? _processorClient;
        private bool _isStarted = false;
        private readonly Dictionary<string, DateTime> _lastAlertTimeByDevice = new Dictionary<string, DateTime>();

        public TelemetryProcessorService(
            IOptions<ProcessingOptions> options, 
            ILogger<TelemetryProcessorService> logger,
            IAlertManager alertManager,
            IDeviceCommunication deviceCommunication)
        {
            _logger = logger;
            _options = options.Value;
            _alertManager = alertManager;
            _deviceCommunication = deviceCommunication;

            // Initialize Cosmos DB client
            _cosmosClient = new CosmosClient(_options.CosmosDbConnectionString);
            _telemetryContainer = _cosmosClient.GetContainer(_options.CosmosDbDatabaseName, _options.TelemetryContainerName);
            _waterQualityContainer = _cosmosClient.GetContainer(_options.CosmosDbDatabaseName, _options.WaterQualityContainerName);
        }

        public async Task StartProcessingAsync()
        {
            if (_isStarted)
            {
                _logger.LogWarning("Telemetry processor is already running");
                return;
            }

            try
            {
                // Create a blob container client for the checkpoint store
                var storageClient = new BlobContainerClient(_options.StorageConnectionString, _options.StorageContainerName);
                await storageClient.CreateIfNotExistsAsync();

                // Create an event processor client to process events from the event hub
                _processorClient = new EventProcessorClient(
                    storageClient,
                    _options.ConsumerGroup,
                    _options.EventHubConnectionString,
                    _options.EventHubName);

                // Register handlers for processing events and handling errors
                _processorClient.ProcessEventAsync += ProcessEventHandler;
                _processorClient.ProcessErrorAsync += ProcessErrorHandler;

                // Start the processing
                _processorClient.StartProcessing();
                _isStarted = true;

                _logger.LogInformation("Telemetry processor started");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error starting telemetry processor");
                throw;
            }
        }

        public async Task StopProcessingAsync()
        {
            if (!_isStarted || _processorClient == null)
            {
                _logger.LogWarning("Telemetry processor is not running");
                return;
            }

            try
            {
                // Stop the processor client
                await _processorClient.StopProcessingAsync();
                _processorClient.ProcessEventAsync -= ProcessEventHandler;
                _processorClient.ProcessErrorAsync -= ProcessErrorHandler;
                _isStarted = false;

                _logger.LogInformation("Telemetry processor stopped");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error stopping telemetry processor");
                throw;
            }
        }

        public async Task ProcessTelemetryAsync(TelemetryReading reading)
        {
            try
            {
                _logger.LogDebug("Processing telemetry from device {DeviceId}", reading.DeviceId);

                // Store the telemetry in Cosmos DB
                await _telemetryContainer.CreateItemAsync(reading, new PartitionKey(reading.DeviceId));

                // Update the device's last telemetry in the device communication service
                await _deviceCommunication.UpdateTelemetryCacheAsync(reading);

                // Check if any alerts should be raised
                await CheckForAlertsAsync(reading);

                // Add to cache for history
                await AddToTelemetryCacheAsync(reading);

                _logger.LogDebug("Telemetry from device {DeviceId} processed successfully", reading.DeviceId);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error processing telemetry from device {DeviceId}", reading.DeviceId);
            }
        }

        public async Task ProcessBatchTelemetryAsync(IEnumerable<TelemetryReading> readings)
        {
            var tasks = new List<Task>();
            foreach (var reading in readings)
            {
                tasks.Add(ProcessTelemetryAsync(reading));
                
                // Throttle the number of concurrent tasks
                if (tasks.Count >= _options.MaxConcurrentProcessingTasks)
                {
                    await Task.WhenAny(tasks);
                    tasks.RemoveAll(t => t.IsCompleted);
                }
            }

            // Wait for remaining tasks to complete
            await Task.WhenAll(tasks);
        }

        public async Task<IEnumerable<TelemetryReading>> GetTelemetryHistoryAsync(string deviceId, DateTime startTime, DateTime endTime)
        {
            try
            {
                // Check cache first for recent data
                var cachedReadings = await GetCachedTelemetryAsync(deviceId, startTime, endTime);
                if (cachedReadings.Any())
                {
                    return cachedReadings;
                }

                // Query Cosmos DB for historical data
                string query = $"SELECT * FROM c WHERE c.deviceId = @deviceId AND c.timestamp >= @startTime AND c.timestamp <= @endTime ORDER BY c.timestamp DESC";
                var queryDef = new QueryDefinition(query)
                    .WithParameter("@deviceId", deviceId)
                    .WithParameter("@startTime", startTime.ToString("o"))
                    .WithParameter("@endTime", endTime.ToString("o"));

                var results = new List<TelemetryReading>();
                var iterator = _telemetryContainer.GetItemQueryIterator<TelemetryReading>(queryDef);

                while (iterator.HasMoreResults)
                {
                    var response = await iterator.ReadNextAsync();
                    results.AddRange(response);
                }

                return results;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting telemetry history for device {DeviceId}", deviceId);
                return Enumerable.Empty<TelemetryReading>();
            }
        }

        public async Task<WaterQualityReport> GenerateWaterQualityReportAsync(string deviceId)
        {
            try
            {
                // Get recent telemetry (last 24 hours)
                var endTime = DateTime.UtcNow;
                var startTime = endTime.AddHours(-24);

                var telemetryHistory = await GetTelemetryHistoryAsync(deviceId, startTime, endTime);

                if (!telemetryHistory.Any())
                {
                    throw new InvalidOperationException($"No recent telemetry found for device {deviceId}");
                }

                // Calculate average water quality metrics
                var avgQuality = telemetryHistory.Average(t => t.WaterQuality);
                var latestReading = telemetryHistory.OrderByDescending(t => t.Timestamp).First();

                // Generate a water quality report
                var report = new WaterQualityReport
                {
                    DeviceId = deviceId,
                    Timestamp = DateTime.UtcNow,
                    OverallQualityScore = avgQuality,
                    PH = 7.2, // Mock value, should be derived from actual sensors
                    Turbidity = 0.5, // Mock value, should be derived from actual sensors
                    DissolvedOxygen = 8.5, // Mock value, should be derived from actual sensors
                    TotalDissolvedSolids = 150, // Mock value, should be derived from actual sensors
                    Conductivity = 320, // Mock value, should be derived from actual sensors
                    Temperature = latestReading.Temperature,
                    ChlorineLevels = 1.2, // Mock value, should be derived from actual sensors
                    MeetsRegulationStandards = avgQuality >= _options.WaterQualityThreshold
                };

                // Add some contaminants based on quality score
                if (avgQuality < 95)
                {
                    report.Contaminants.Add(new WaterContaminant
                    {
                        Name = "Total Coliform",
                        Concentration = 2.5,
                        Unit = "cfu/100mL",
                        MaxAllowedConcentration = 5.0
                    });
                }

                if (avgQuality < 85)
                {
                    report.Contaminants.Add(new WaterContaminant
                    {
                        Name = "Lead",
                        Concentration = 0.011,
                        Unit = "mg/L",
                        MaxAllowedConcentration = 0.015
                    });
                }

                if (avgQuality < 70)
                {
                    report.Contaminants.Add(new WaterContaminant
                    {
                        Name = "Nitrates",
                        Concentration = 11.5,
                        Unit = "mg/L",
                        MaxAllowedConcentration = 10.0
                    });
                }

                // Save the report to Cosmos DB
                await _waterQualityContainer.CreateItemAsync(report, new PartitionKey(deviceId));

                return report;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error generating water quality report for device {DeviceId}", deviceId);
                throw;
            }
        }

        private async Task ProcessEventHandler(ProcessEventArgs args)
        {
            try
            {
                // Read the telemetry data from the event
                var messageBody = Encoding.UTF8.GetString(args.Data.Body.ToArray());
                var telemetry = JsonConvert.DeserializeObject<TelemetryReading>(messageBody);

                if (telemetry != null)
                {
                    // Process the telemetry reading
                    await ProcessTelemetryAsync(telemetry);
                }
                else
                {
                    _logger.LogWarning("Received null or invalid telemetry data");
                }

                // Update the checkpoint
                await args.UpdateCheckpointAsync(args.CancellationToken);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in telemetry event handler");
            }
        }

        private Task ProcessErrorHandler(ProcessErrorEventArgs args)
        {
            _logger.LogError(args.Exception, "Error in event processor: {ErrorMessage}", args.Exception.Message);
            return Task.CompletedTask;
        }

        private async Task CheckForAlertsAsync(TelemetryReading reading)
        {
            try
            {
                // Check if we've recently sent an alert for this device to avoid alert floods
                if (_lastAlertTimeByDevice.TryGetValue(reading.DeviceId, out DateTime lastAlertTime))
                {
                    var timeSinceLastAlert = DateTime.UtcNow - lastAlertTime;
                    if (timeSinceLastAlert.TotalMinutes < _options.AlertThresholdPeriodMinutes)
                    {
                        // Skip alert checking if too recent
                        return;
                    }
                }

                var alerts = new List<Alert>();

                // Check water level
                if (reading.WaterLevelStatus == WaterLevelStatus.High || reading.WaterLevelStatus == WaterLevelStatus.Critical)
                {
                    alerts.Add(new Alert
                    {
                        DeviceId = reading.DeviceId,
                        Type = AlertType.HighWaterLevel,
                        Severity = reading.WaterLevelStatus == WaterLevelStatus.Critical ? 
                            AlertSeverity.Emergency : AlertSeverity.Warning,
                        Message = $"High water level detected: {reading.WaterLevelStatus}",
                        Timestamp = DateTime.UtcNow
                    });
                }
                else if (reading.WaterLevelStatus == WaterLevelStatus.Low)
                {
                    alerts.Add(new Alert
                    {
                        DeviceId = reading.DeviceId,
                        Type = AlertType.LowWaterLevel,
                        Severity = AlertSeverity.Warning,
                        Message = "Low water level detected",
                        Timestamp = DateTime.UtcNow
                    });
                }

                // Check water pressure
                if (reading.WaterPressure > _options.HighPressureThreshold)
                {
                    alerts.Add(new Alert
                    {
                        DeviceId = reading.DeviceId,
                        Type = AlertType.HighPressure,
                        Severity = AlertSeverity.Warning,
                        Message = $"High water pressure detected: {reading.WaterPressure} Pa",
                        Timestamp = DateTime.UtcNow
                    });
                }
                else if (reading.WaterPressure < _options.LowPressureThreshold)
                {
                    alerts.Add(new Alert
                    {
                        DeviceId = reading.DeviceId,
                        Type = AlertType.LowPressure,
                        Severity = AlertSeverity.Warning,
                        Message = $"Low water pressure detected: {reading.WaterPressure} Pa",
                        Timestamp = DateTime.UtcNow
                    });
                }

                // Check water quality
                if (reading.WaterQuality < _options.WaterQualityThreshold)
                {
                    alerts.Add(new Alert
                    {
                        DeviceId = reading.DeviceId,
                        Type = AlertType.PoorWaterQuality,
                        Severity = reading.WaterQuality < _options.WaterQualityThreshold / 2 ? 
                            AlertSeverity.Critical : AlertSeverity.Warning,
                        Message = $"Poor water quality detected: {reading.WaterQuality}",
                        Timestamp = DateTime.UtcNow,
                        AdditionalInfo = new Dictionary<string, string>
                        {
                            { "QualityScore", reading.WaterQuality.ToString() },
                            { "Threshold", _options.WaterQualityThreshold.ToString() }
                        }
                    });
                }

                // Check battery level
                if (reading.BatteryLevel < _options.BatteryLowThreshold)
                {
                    alerts.Add(new Alert
                    {
                        DeviceId = reading.DeviceId,
                        Type = AlertType.BatteryLow,
                        Severity = reading.BatteryLevel < _options.BatteryLowThreshold / 2 ? 
                            AlertSeverity.Critical : AlertSeverity.Warning,
                        Message = $"Low battery level detected: {reading.BatteryLevel}%",
                        Timestamp = DateTime.UtcNow
                    });
                }

                // Submit all alerts
                foreach (var alert in alerts)
                {
                    await _alertManager.CreateAlertAsync(alert);
                }

                // If any alerts were raised, update the last alert time
                if (alerts.Any())
                {
                    _lastAlertTimeByDevice[reading.DeviceId] = DateTime.UtcNow;
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error checking for alerts from device {DeviceId}", reading.DeviceId);
            }
        }

        private async Task AddToTelemetryCacheAsync(TelemetryReading reading)
        {
            try
            {
                await _cacheLock.WaitAsync();
                
                if (!_telemetryCache.TryGetValue(reading.DeviceId, out var deviceReadings))
                {
                    deviceReadings = new List<TelemetryReading>();
                    _telemetryCache[reading.DeviceId] = deviceReadings;
                }

                // Add the new reading
                deviceReadings.Add(reading);

                // Keep only the last 100 readings per device
                if (deviceReadings.Count > 100)
                {
                    _telemetryCache[reading.DeviceId] = deviceReadings
                        .OrderByDescending(r => r.Timestamp)
                        .Take(100)
                        .ToList();
                }
            }
            finally
            {
                _cacheLock.Release();
            }
        }

        private async Task<IEnumerable<TelemetryReading>> GetCachedTelemetryAsync(
            string deviceId, DateTime startTime, DateTime endTime)
        {
            try
            {
                await _cacheLock.WaitAsync();
                
                if (!_telemetryCache.TryGetValue(deviceId, out var deviceReadings))
                {
                    return Enumerable.Empty<TelemetryReading>();
                }

                return deviceReadings
                    .Where(r => r.Timestamp >= startTime && r.Timestamp <= endTime)
                    .OrderByDescending(r => r.Timestamp)
                    .ToList();
            }
            finally
            {
                _cacheLock.Release();
            }
        }

        public async ValueTask DisposeAsync()
        {
            if (_isStarted && _processorClient != null)
            {
                await StopProcessingAsync();
            }

            _cosmosClient?.Dispose();
            _cacheLock?.Dispose();
        }
    }
}

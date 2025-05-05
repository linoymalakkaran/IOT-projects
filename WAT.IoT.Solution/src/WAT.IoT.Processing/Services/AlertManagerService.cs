// WAT.IoT.Processing/Services/AlertManagerService.cs
using Microsoft.Azure.Cosmos;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using WAT.IoT.Core.Interfaces;
using WAT.IoT.Core.Models;
using WAT.IoT.Processing.Configuration;

namespace WAT.IoT.Processing.Services
{
    public class AlertManagerService : IAlertManager
    {
        private readonly ILogger<AlertManagerService> _logger;
        private readonly ProcessingOptions _options;
        private readonly CosmosClient _cosmosClient;
        private readonly Container _eventsContainer;

        public AlertManagerService(
            IOptions<ProcessingOptions> options,
            ILogger<AlertManagerService> logger)
        {
            _logger = logger;
            _options = options.Value;

            // Initialize Cosmos DB client
            _cosmosClient = new CosmosClient(_options.CosmosDbConnectionString);
            _eventsContainer = _cosmosClient.GetContainer(_options.CosmosDbDatabaseName, _options.EventsContainerName);
        }

        public async Task<string> CreateAlertAsync(Alert alert)
        {
            try
            {
                _logger.LogInformation("Creating alert: {AlertType} for device {DeviceId}", alert.Type, alert.DeviceId);
                
                // Generate a new alert ID if not provided
                if (string.IsNullOrEmpty(alert.AlertId))
                {
                    alert.AlertId = Guid.NewGuid().ToString();
                }

                // Store the alert in Cosmos DB
                var response = await _eventsContainer.CreateItemAsync(alert, new PartitionKey(alert.Type.ToString()));
                
                _logger.LogInformation("Alert created with ID: {AlertId}", alert.AlertId);
                return alert.AlertId;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating alert for device {DeviceId}", alert.DeviceId);
                throw;
            }
        }

        public async Task<bool> AcknowledgeAlertAsync(string alertId, string acknowledgedBy)
        {
            try
            {
                _logger.LogInformation("Acknowledging alert {AlertId} by {User}", alertId, acknowledgedBy);

                // Define a query to find the alert by ID
                string query = "SELECT * FROM c WHERE c.alertId = @alertId";
                var queryDef = new QueryDefinition(query)
                    .WithParameter("@alertId", alertId);

                var iterator = _eventsContainer.GetItemQueryIterator<Alert>(queryDef);
                
                while (iterator.HasMoreResults)
                {
                    var response = await iterator.ReadNextAsync();
                    
                    if (response.Count > 0)
                    {
                        var alert = response.First();
                        alert.Acknowledged = true;
                        alert.AcknowledgedTime = DateTime.UtcNow;
                        alert.AcknowledgedBy = acknowledgedBy;

                        // Update the alert in Cosmos DB
                        await _eventsContainer.ReplaceItemAsync(alert, alert.AlertId, new PartitionKey(alert.Type.ToString()));
                        _logger.LogInformation("Alert {AlertId} acknowledged", alertId);
                        return true;
                    }
                }

                _logger.LogWarning("Alert {AlertId} not found for acknowledgment", alertId);
                return false;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error acknowledging alert {AlertId}", alertId);
                return false;
            }
        }

        public async Task<IEnumerable<Alert>> GetActiveAlertsAsync()
        {
            try
            {
                _logger.LogInformation("Getting active alerts");

                // Define a query to find unacknowledged alerts
                string query = "SELECT * FROM c WHERE c.acknowledged = false ORDER BY c.timestamp DESC";
                var queryDef = new QueryDefinition(query);

                var results = new List<Alert>();
                var iterator = _eventsContainer.GetItemQueryIterator<Alert>(queryDef);
                
                while (iterator.HasMoreResults)
                {
                    var response = await iterator.ReadNextAsync();
                    results.AddRange(response);
                }

                _logger.LogInformation("Retrieved {Count} active alerts", results.Count);
                return results;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting active alerts");
                return Enumerable.Empty<Alert>();
            }
        }

        public async Task<IEnumerable<Alert>> GetAlertsByDeviceAsync(string deviceId)
        {
            try
            {
                _logger.LogInformation("Getting alerts for device {DeviceId}", deviceId);

                // Define a query to find alerts for a specific device
                string query = "SELECT * FROM c WHERE c.deviceId = @deviceId ORDER BY c.timestamp DESC";
                var queryDef = new QueryDefinition(query)
                    .WithParameter("@deviceId", deviceId);

                var results = new List<Alert>();
                var iterator = _eventsContainer.GetItemQueryIterator<Alert>(queryDef);
                
                while (iterator.HasMoreResults)
                {
                    var response = await iterator.ReadNextAsync();
                    results.AddRange(response);
                }

                _logger.LogInformation("Retrieved {Count} alerts for device {DeviceId}", results.Count, deviceId);
                return results;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting alerts for device {DeviceId}", deviceId);
                return Enumerable.Empty<Alert>();
            }
        }

        public async Task<IEnumerable<Alert>> GetAlertsByTypeAsync(AlertType type)
        {
            try
            {
                _logger.LogInformation("Getting alerts of type {AlertType}", type);

                // Define a query to find alerts of a specific type
                string query = "SELECT * FROM c WHERE c.type = @type ORDER BY c.timestamp DESC";
                var queryDef = new QueryDefinition(query)
                    .WithParameter("@type", type.ToString());

                var results = new List<Alert>();
                var iterator = _eventsContainer.GetItemQueryIterator<Alert>(queryDef, requestOptions: new QueryRequestOptions { PartitionKey = new PartitionKey(type.ToString()) });
                
                while (iterator.HasMoreResults)
                {
                    var response = await iterator.ReadNextAsync();
                    results.AddRange(response);
                }

                _logger.LogInformation("Retrieved {Count} alerts of type {AlertType}", results.Count, type);
                return results;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting alerts of type {AlertType}", type);
                return Enumerable.Empty<Alert>();
            }
        }

        public async Task<IEnumerable<Alert>> GetAlertsByDateRangeAsync(DateTime startTime, DateTime endTime)
        {
            try
            {
                _logger.LogInformation("Getting alerts between {StartTime} and {EndTime}", startTime, endTime);

                // Define a query to find alerts within a date range
                string query = "SELECT * FROM c WHERE c.timestamp >= @startTime AND c.timestamp <= @endTime ORDER BY c.timestamp DESC";
                var queryDef = new QueryDefinition(query)
                    .WithParameter("@startTime", startTime.ToString("o"))
                    .WithParameter("@endTime", endTime.ToString("o"));

                var results = new List<Alert>();
                var iterator = _eventsContainer.GetItemQueryIterator<Alert>(queryDef);
                
                while (iterator.HasMoreResults)
                {
                    var response = await iterator.ReadNextAsync();
                    results.AddRange(response);
                }

                _logger.LogInformation("Retrieved {Count} alerts between {StartTime} and {EndTime}", results.Count, startTime, endTime);
                return results;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting alerts by date range");
                return Enumerable.Empty<Alert>();
            }
        }
    }
}

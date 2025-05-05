// WAT.IoT.Processing/Configuration/ProcessingOptions.cs
namespace WAT.IoT.Processing.Configuration
{
    public class ProcessingOptions
    {
        public string EventHubConnectionString { get; set; } = string.Empty;
        public string EventHubName { get; set; } = "telemetry";
        public string ConsumerGroup { get; set; } = "";
        public string CosmosDbConnectionString { get; set; } = string.Empty;
        public string CosmosDbDatabaseName { get; set; } = "WATOperationalData";
        public string TelemetryContainerName { get; set; } = "telemetry";
        public string EventsContainerName { get; set; } = "events";
        public string WaterQualityContainerName { get; set; } = "waterQuality";
        public string StorageConnectionString { get; set; } = string.Empty;
        public string StorageContainerName { get; set; } = "checkpoints";
        public int TelemetryProcessingBatchSize { get; set; } = 100;
        public int MaxConcurrentProcessingTasks { get; set; } = 10;
        public int AlertThresholdPeriodMinutes { get; set; } = 10;
        public bool EnableAnomalyDetection { get; set; } = true;
        public double HighWaterLevelThreshold { get; set; } = 80.0;
        public double LowWaterLevelThreshold { get; set; } = 20.0;
        public double HighPressureThreshold { get; set; } = 100.0;
        public double LowPressureThreshold { get; set; } = 10.0;
        public double WaterQualityThreshold { get; set; } = 50.0;
        public double BatteryLowThreshold { get; set; } = 15.0;
    }
}

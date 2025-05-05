// WAT.IoT.Core/Models/Alert.cs
namespace WAT.IoT.Core.Models
{
    public class Alert
    {
        public string AlertId { get; set; } = Guid.NewGuid().ToString();
        public string DeviceId { get; set; } = string.Empty;
        public AlertType Type { get; set; }
        public AlertSeverity Severity { get; set; }
        public string Message { get; set; } = string.Empty;
        public DateTime Timestamp { get; set; } = DateTime.UtcNow;
        public bool Acknowledged { get; set; } = false;
        public DateTime? AcknowledgedTime { get; set; }
        public string? AcknowledgedBy { get; set; }
        public Dictionary<string, string> AdditionalInfo { get; set; } = new Dictionary<string, string>();
    }

    public enum AlertType
    {
        HighWaterLevel,
        LowWaterLevel,
        HighPressure,
        LowPressure,
        PoorWaterQuality,
        DeviceOffline,
        ValveFailure,
        BatteryLow,
        PowerOutage,
        UnauthorizedAccess,
        CommunicationFailure
    }

    public enum AlertSeverity
    {
        Information,
        Warning,
        Critical,
        Emergency
    }
}

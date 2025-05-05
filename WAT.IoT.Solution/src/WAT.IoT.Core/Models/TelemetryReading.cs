// WAT.IoT.Core/Models/TelemetryReading.cs
namespace WAT.IoT.Core.Models
{
    public class TelemetryReading
    {
        public string DeviceId { get; set; } = string.Empty;
        public DateTime Timestamp { get; set; } = DateTime.UtcNow;
        public double WaterFlowRate { get; set; } // in liters per minute
        public double WaterPressure { get; set; } // in pascals
        public double WaterQuality { get; set; } // 0-100 scale (100 being best quality)
        public double BatteryLevel { get; set; } // percentage 0-100
        public ValveStatus ValveStatus { get; set; } = ValveStatus.Open;
        public double Temperature { get; set; } // in Celsius
        public WaterLevelStatus WaterLevelStatus { get; set; } = WaterLevelStatus.Normal;
    }

    public enum ValveStatus
    {
        Open,
        Closed,
        Partially
    }

    public enum WaterLevelStatus
    {
        Low,
        Normal,
        High,
        Critical
    }
}

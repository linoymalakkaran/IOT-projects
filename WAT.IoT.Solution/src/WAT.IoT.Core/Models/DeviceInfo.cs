// WAT.IoT.Core/Models/DeviceInfo.cs
namespace WAT.IoT.Core.Models
{
    public class DeviceInfo
    {
        public string DeviceId { get; set; } = string.Empty;
        public string DeviceType { get; set; } = "WaterMeter";
        public string FirmwareVersion { get; set; } = "1.0.0";
        public string Location { get; set; } = string.Empty;
        public string ConnectionType { get; set; } = "LoRaWAN";
        public bool IsActive { get; set; } = true;
        public DateTime LastActivityTime { get; set; } = DateTime.UtcNow;
        public Dictionary<string, string> Tags { get; set; } = new Dictionary<string, string>();
    }
}

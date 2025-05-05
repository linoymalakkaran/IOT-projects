// WAT.IoT.Core/Models/ValveCommand.cs
namespace WAT.IoT.Core.Models
{
    public class ValveCommand
    {
        public string DeviceId { get; set; } = string.Empty;
        public ValveAction Action { get; set; }
        public string Reason { get; set; } = string.Empty;
        public DateTime Timestamp { get; set; } = DateTime.UtcNow;
        public string IssuedBy { get; set; } = string.Empty; // System or User ID
    }

    public enum ValveAction
    {
        Open,
        Close,
        PartialOpen
    }
}

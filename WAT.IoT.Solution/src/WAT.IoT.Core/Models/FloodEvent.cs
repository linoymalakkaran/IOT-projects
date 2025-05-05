// WAT.IoT.Core/Models/FloodEvent.cs
namespace WAT.IoT.Core.Models
{
    public class FloodEvent
    {
        public string EventId { get; set; } = Guid.NewGuid().ToString();
        public DateTime StartTime { get; set; } = DateTime.UtcNow;
        public DateTime? EndTime { get; set; }
        public string Location { get; set; } = string.Empty;
        public List<string> AffectedDeviceIds { get; set; } = new List<string>();
        public FloodSeverity Severity { get; set; }
        public double PeakWaterLevel { get; set; }
        public double EstimatedVolumeReleased { get; set; } // in cubic meters
        public bool HasRegulationReport { get; set; } = false;
        public DateTime? RegulationReportTime { get; set; }
        public string? ReportSubmittedBy { get; set; }
    }

    public enum FloodSeverity
    {
        Minor,
        Moderate,
        Major,
        Catastrophic
    }
}

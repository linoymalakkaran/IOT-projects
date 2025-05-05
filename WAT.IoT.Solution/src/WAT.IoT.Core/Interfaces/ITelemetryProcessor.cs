// WAT.IoT.Core/Interfaces/ITelemetryProcessor.cs
using WAT.IoT.Core.Models;

namespace WAT.IoT.Core.Interfaces
{
    public interface ITelemetryProcessor
    {
        Task ProcessTelemetryAsync(TelemetryReading reading);
        Task ProcessBatchTelemetryAsync(IEnumerable<TelemetryReading> readings);
        Task<IEnumerable<TelemetryReading>> GetTelemetryHistoryAsync(string deviceId, DateTime startTime, DateTime endTime);
        Task<WaterQualityReport> GenerateWaterQualityReportAsync(string deviceId);
    }
}

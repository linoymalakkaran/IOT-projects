// WAT.IoT.Core/Interfaces/IScadaIntegration.cs
using WAT.IoT.Core.Models;

namespace WAT.IoT.Core.Interfaces
{
    public interface IScadaIntegration
    {
        Task SendTelemetryToScadaAsync(TelemetryReading telemetry);
        Task SendAlertToScadaAsync(Alert alert);
        Task NotifyValveOperationAsync(string deviceId, ValveAction action);
        Task NotifyFloodEventAsync(FloodEvent floodEvent);
        Task<bool> ReceiveCommandFromScadaAsync(ValveCommand command);
    }
}

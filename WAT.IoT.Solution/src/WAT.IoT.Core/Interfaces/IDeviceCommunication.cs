// WAT.IoT.Core/Interfaces/IDeviceCommunication.cs
using WAT.IoT.Core.Models;

namespace WAT.IoT.Core.Interfaces
{
    public interface IDeviceCommunication
    {
        Task<bool> SendCommandAsync(string deviceId, ValveCommand command);
        Task<bool> SendCommandBatchAsync(IEnumerable<ValveCommand> commands);
        Task<TelemetryReading?> GetLatestTelemetryAsync(string deviceId);
        Task<bool> IsDeviceOnlineAsync(string deviceId);
        Task<DeviceConnectionStatus> GetConnectionStatusAsync(string deviceId);
        Task UpdateTelemetryCacheAsync(TelemetryReading reading);
    }

    public enum DeviceConnectionStatus
    {
        Online,
        Offline,
        Degraded,
        Unknown
    }
}

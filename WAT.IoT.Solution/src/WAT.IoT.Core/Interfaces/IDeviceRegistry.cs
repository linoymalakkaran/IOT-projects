// WAT.IoT.Core/Interfaces/IDeviceRegistry.cs
using WAT.IoT.Core.Models;

namespace WAT.IoT.Core.Interfaces
{
    public interface IDeviceRegistry
    {
        Task<DeviceInfo> GetDeviceInfoAsync(string deviceId);
        Task<IEnumerable<DeviceInfo>> GetAllDevicesAsync();
        Task<IEnumerable<DeviceInfo>> GetDevicesByLocationAsync(string location);
        Task<bool> AddDeviceAsync(DeviceInfo device);
        Task<bool> UpdateDeviceAsync(DeviceInfo device);
        Task<bool> DeleteDeviceAsync(string deviceId);
        Task<bool> IsDeviceRegisteredAsync(string deviceId);
    }
}

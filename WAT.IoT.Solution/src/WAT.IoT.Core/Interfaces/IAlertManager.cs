// WAT.IoT.Core/Interfaces/IAlertManager.cs
using WAT.IoT.Core.Models;

namespace WAT.IoT.Core.Interfaces
{
    public interface IAlertManager
    {
        Task<string> CreateAlertAsync(Alert alert);
        Task<bool> AcknowledgeAlertAsync(string alertId, string acknowledgedBy);
        Task<IEnumerable<Alert>> GetActiveAlertsAsync();
        Task<IEnumerable<Alert>> GetAlertsByDeviceAsync(string deviceId);
        Task<IEnumerable<Alert>> GetAlertsByTypeAsync(AlertType type);
        Task<IEnumerable<Alert>> GetAlertsByDateRangeAsync(DateTime startTime, DateTime endTime);
    }
}

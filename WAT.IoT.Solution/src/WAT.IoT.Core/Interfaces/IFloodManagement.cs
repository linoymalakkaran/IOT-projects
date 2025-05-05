// WAT.IoT.Core/Interfaces/IFloodManagement.cs
using WAT.IoT.Core.Models;

namespace WAT.IoT.Core.Interfaces
{
    public interface IFloodManagement
    {
        Task<string> CreateFloodEventAsync(FloodEvent floodEvent);
        Task<bool> UpdateFloodEventAsync(FloodEvent floodEvent);
        Task<bool> CloseFloodEventAsync(string eventId, DateTime endTime);
        Task<bool> SubmitRegulationReportAsync(string eventId, string submittedBy);
        Task<IEnumerable<FloodEvent>> GetActiveFloodEventsAsync();
        Task<IEnumerable<FloodEvent>> GetFloodEventsByDateRangeAsync(DateTime startTime, DateTime endTime);
        Task<FloodEvent?> GetFloodEventByIdAsync(string eventId);
    }
}

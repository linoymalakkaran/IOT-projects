// WAT.IoT.Web/Models/DashboardViewModel.cs
using WAT.IoT.Core.Models;

namespace WAT.IoT.Web.Models
{
    public class DashboardViewModel
    {
        public int TotalDevices { get; set; }
        public int OnlineDevices { get; set; }
        public int OfflineDevices { get; set; }
        public int ActiveAlerts { get; set; }
        public int CriticalAlerts { get; set; }
        public double AverageWaterQuality { get; set; }
        public List<DeviceInfo> RecentDevices { get; set; } = new List<DeviceInfo>();
        public List<Alert> RecentAlerts { get; set; } = new List<Alert>();
        public List<FloodEvent> ActiveFloodEvents { get; set; } = new List<FloodEvent>();
    }
}

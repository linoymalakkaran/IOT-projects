// WAT.IoT.Devices/Configuration/IoTHubOptions.cs
namespace WAT.IoT.Devices.Configuration
{
    public class IoTHubOptions
    {
        public string ConnectionString { get; set; } = string.Empty;
        public string DpsIdScope { get; set; } = string.Empty;
        public string DpsGlobalEndpoint { get; set; } = "global.azure-devices-provisioning.net";
        public int DefaultTimeoutSeconds { get; set; } = 30;
        public bool EnableTwinSync { get; set; } = true;
        public bool EnableLogging { get; set; } = true;
        public int RetryCount { get; set; } = 3;
        public int RetryIntervalMilliseconds { get; set; } = 1000;
    }
}

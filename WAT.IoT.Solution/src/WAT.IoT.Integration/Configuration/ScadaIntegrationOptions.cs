// WAT.IoT.Integration/Configuration/ScadaIntegrationOptions.cs
namespace WAT.IoT.Integration.Configuration
{
    public class ScadaIntegrationOptions
    {
        public string ScadaApiBaseUrl { get; set; } = "http://localhost:5000/api/scada";
        public string TelemetryEndpoint { get; set; } = "telemetry";
        public string AlertEndpoint { get; set; } = "alert";
        public string ValveOperationEndpoint { get; set; } = "valve";
        public string FloodEventEndpoint { get; set; } = "flood";
        public string ApiKey { get; set; } = string.Empty;
        public int TimeoutSeconds { get; set; } = 30;
        public int RetryCount { get; set; } = 3;
        public bool EnableMock { get; set; } = true;
    }
}

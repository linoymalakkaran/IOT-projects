# WAT-IoT-Solution-Generator.ps1

param (
    [string]$outputPath = ".\WAT.IoT.Solution"
)

# At the beginning of the script, after the param section:
$ErrorActionPreference = "Stop"

# Ensure the output path is absolute and properly formatted
if (-not [System.IO.Path]::IsPathRooted($outputPath)) {
    $outputPath = [System.IO.Path]::GetFullPath((Join-Path (Get-Location) $outputPath))
}

Write-Host "Starting WAT IoT-Based Monitoring and Control Solution generation..." -ForegroundColor Green
Write-Host "Output path: $outputPath"

# Create the base output directory
if (-not (Test-Path $outputPath)) {
    New-Item -ItemType Directory -Path $outputPath -Force | Out-Null
}

#region Create Directory Structure
Write-Host "Creating directory structure..." -ForegroundColor Cyan

# Create main solution directories
$directories = @(
    "src",
    "simulator",
    "tests",
    "docs"
)

foreach ($dir in $directories) {
    $path = Join-Path -Path $outputPath -ChildPath $dir
    if (-not (Test-Path $path)) {
        New-Item -ItemType Directory -Path $path | Out-Null
        Write-Host "  Created directory: $dir"
    }
}

# Create source project directories
$srcDirectories = @(
    "WAT.IoT.Core",
    "WAT.IoT.Devices",
    "WAT.IoT.Processing",
    "WAT.IoT.Integration",
    "WAT.IoT.Api",
    "WAT.IoT.Functions",
    "WAT.IoT.Web"
)

foreach ($dir in $srcDirectories) {
    $path = Join-Path -Path $outputPath -ChildPath "src\$dir"
    if (-not (Test-Path $path)) {
        New-Item -ItemType Directory -Path $path | Out-Null
        Write-Host "  Created directory: src\$dir"
    }
}

# Create simulator project directories
$simulatorDirectories = @(
    "WAT.IoT.Simulator.Core",
    "WAT.IoT.Simulator.Devices",
    "WAT.IoT.Simulator.Runner"
)

foreach ($dir in $simulatorDirectories) {
    $path = Join-Path -Path $outputPath -ChildPath "simulator\$dir"
    if (-not (Test-Path $path)) {
        New-Item -ItemType Directory -Path $path | Out-Null
        Write-Host "  Created directory: simulator\$dir"
    }
}

# Create test project directories
$testDirectories = @(
    "WAT.IoT.Core.Tests",
    "WAT.IoT.Devices.Tests",
    "WAT.IoT.Simulator.Tests"
)

foreach ($dir in $testDirectories) {
    $path = Join-Path -Path $outputPath -ChildPath "tests\$dir"
    if (-not (Test-Path $path)) {
        New-Item -ItemType Directory -Path $path | Out-Null
        Write-Host "  Created directory: tests\$dir"
    }
}

# Create subdirectories for specific projects
$projectSubdirectories = @{
    "src\WAT.IoT.Core" = @("Interfaces", "Models")
    "src\WAT.IoT.Devices" = @("Configuration", "Services", "Helpers")
    "src\WAT.IoT.Processing" = @("Configuration", "Services")
    "src\WAT.IoT.Integration" = @("Configuration", "Services")
    "src\WAT.IoT.Api" = @("Controllers", "Middlewares")
    "src\WAT.IoT.Functions" = @("Functions")
    "src\WAT.IoT.Web" = @("Controllers", "Views", "Models", "wwwroot")
    "simulator\WAT.IoT.Simulator.Core" = @("Interfaces", "Models")
    "simulator\WAT.IoT.Simulator.Devices" = @("Configuration", "Transport")
    "simulator\WAT.IoT.Simulator.Runner" = @("Commands", "Models", "scenarios")
}

foreach ($project in $projectSubdirectories.Keys) {
    foreach ($subdir in $projectSubdirectories[$project]) {
        $path = Join-Path -Path $outputPath -ChildPath "$project\$subdir"
        if (-not (Test-Path $path)) {
            New-Item -ItemType Directory -Path $path | Out-Null
            Write-Host "  Created directory: $project\$subdir"
        }
    }
}

Write-Host "Directory structure created successfully" -ForegroundColor Green
#endregion

#region Create Solution File
Write-Host "Creating solution file..." -ForegroundColor Cyan

$solutionFilePath = Join-Path -Path $outputPath -ChildPath "WAT.IoT.Solution.sln"

# Create the solution file using dotnet CLI
if (-not (Test-Path $solutionFilePath)) {
    Set-Location $outputPath
    & dotnet new sln -n "WAT.IoT.Solution"
    Write-Host "  Created solution file: WAT.IoT.Solution.sln"
}

Write-Host "Solution file created successfully" -ForegroundColor Green
#endregion

#region Create Core Projects
Write-Host "Creating Core projects..." -ForegroundColor Cyan

$projectPath = Join-Path -Path $outputPath -ChildPath "src\WAT.IoT.Core"
$projectFile = Join-Path -Path $projectPath -ChildPath "WAT.IoT.Core.csproj"

# Create Core project if it doesn't exist
if (-not (Test-Path $projectFile)) {
    # Ensure the directory exists
    if (-not (Test-Path $projectPath)) {
        New-Item -ItemType Directory -Path $projectPath -Force | Out-Null
    }
    
    # Navigate to directory, create project, then return
    Push-Location $projectPath
    & dotnet new classlib
    Pop-Location
    
    # Update Core project file with required packages
    $projectContent = @"
<Project Sdk="Microsoft.NET.Sdk">

  <PropertyGroup>
    <TargetFramework>net6.0</TargetFramework>
    <ImplicitUsings>enable</ImplicitUsings>
    <Nullable>enable</Nullable>
  </PropertyGroup>

  <ItemGroup>
    <PackageReference Include="Microsoft.Extensions.Logging.Abstractions" Version="6.0.0" />
    <PackageReference Include="Newtonsoft.Json" Version="13.0.3" />
  </ItemGroup>

</Project>
"@
    
    Set-Content -Path $projectFile -Value $projectContent
    Write-Host "  Created project: WAT.IoT.Core"
    
    # Add project to solution
    Set-Location $outputPath
    & dotnet sln add "src\WAT.IoT.Core\WAT.IoT.Core.csproj"
}

# Create Core Interfaces
$interfacesPath = Join-Path -Path $projectPath -ChildPath "Interfaces"

# Create IDeviceRegistry.cs
$deviceRegistryPath = Join-Path -Path $interfacesPath -ChildPath "IDeviceRegistry.cs"
$deviceRegistryContent = @"
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
"@
Set-Content -Path $deviceRegistryPath -Value $deviceRegistryContent
Write-Host "  Created: IDeviceRegistry.cs"

# Create IDeviceCommunication.cs
$deviceCommunicationPath = Join-Path -Path $interfacesPath -ChildPath "IDeviceCommunication.cs"
$deviceCommunicationContent = @"
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
    }

    public enum DeviceConnectionStatus
    {
        Online,
        Offline,
        Degraded,
        Unknown
    }
}
"@
Set-Content -Path $deviceCommunicationPath -Value $deviceCommunicationContent
Write-Host "  Created: IDeviceCommunication.cs"

# Create ITelemetryProcessor.cs
$telemetryProcessorPath = Join-Path -Path $interfacesPath -ChildPath "ITelemetryProcessor.cs"
$telemetryProcessorContent = @"
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
"@
Set-Content -Path $telemetryProcessorPath -Value $telemetryProcessorContent
Write-Host "  Created: ITelemetryProcessor.cs"

# Create IAlertManager.cs
$alertManagerPath = Join-Path -Path $interfacesPath -ChildPath "IAlertManager.cs"
$alertManagerContent = @"
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
"@
Set-Content -Path $alertManagerPath -Value $alertManagerContent
Write-Host "  Created: IAlertManager.cs"

# Create IFloodManagement.cs
$floodManagementPath = Join-Path -Path $interfacesPath -ChildPath "IFloodManagement.cs"
$floodManagementContent = @"
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
"@
Set-Content -Path $floodManagementPath -Value $floodManagementContent
Write-Host "  Created: IFloodManagement.cs"

# Create IScadaIntegration.cs
$scadaIntegrationPath = Join-Path -Path $interfacesPath -ChildPath "IScadaIntegration.cs"
$scadaIntegrationContent = @"
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
"@
Set-Content -Path $scadaIntegrationPath -Value $scadaIntegrationContent
Write-Host "  Created: IScadaIntegration.cs"

# Create Core Models
$modelsPath = Join-Path -Path $projectPath -ChildPath "Models"

# Create DeviceInfo.cs
$deviceInfoPath = Join-Path -Path $modelsPath -ChildPath "DeviceInfo.cs"
$deviceInfoContent = @"
// WAT.IoT.Core/Models/DeviceInfo.cs
namespace WAT.IoT.Core.Models
{
    public class DeviceInfo
    {
        public string DeviceId { get; set; } = string.Empty;
        public string DeviceType { get; set; } = "WaterMeter";
        public string FirmwareVersion { get; set; } = "1.0.0";
        public string Location { get; set; } = string.Empty;
        public string ConnectionType { get; set; } = "LoRaWAN";
        public bool IsActive { get; set; } = true;
        public DateTime LastActivityTime { get; set; } = DateTime.UtcNow;
        public Dictionary<string, string> Tags { get; set; } = new Dictionary<string, string>();
    }
}
"@
Set-Content -Path $deviceInfoPath -Value $deviceInfoContent
Write-Host "  Created: DeviceInfo.cs"

# Create TelemetryReading.cs
$telemetryReadingPath = Join-Path -Path $modelsPath -ChildPath "TelemetryReading.cs"
$telemetryReadingContent = @"
// WAT.IoT.Core/Models/TelemetryReading.cs
namespace WAT.IoT.Core.Models
{
    public class TelemetryReading
    {
        public string DeviceId { get; set; } = string.Empty;
        public DateTime Timestamp { get; set; } = DateTime.UtcNow;
        public double WaterFlowRate { get; set; } // in liters per minute
        public double WaterPressure { get; set; } // in pascals
        public double WaterQuality { get; set; } // 0-100 scale (100 being best quality)
        public double BatteryLevel { get; set; } // percentage 0-100
        public ValveStatus ValveStatus { get; set; } = ValveStatus.Open;
        public double Temperature { get; set; } // in Celsius
        public WaterLevelStatus WaterLevelStatus { get; set; } = WaterLevelStatus.Normal;
    }

    public enum ValveStatus
    {
        Open,
        Closed,
        Partially
    }

    public enum WaterLevelStatus
    {
        Low,
        Normal,
        High,
        Critical
    }
}
"@
Set-Content -Path $telemetryReadingPath -Value $telemetryReadingContent
Write-Host "  Created: TelemetryReading.cs"

# Create ValveCommand.cs
$valveCommandPath = Join-Path -Path $modelsPath -ChildPath "ValveCommand.cs"
$valveCommandContent = @"
// WAT.IoT.Core/Models/ValveCommand.cs
namespace WAT.IoT.Core.Models
{
    public class ValveCommand
    {
        public string DeviceId { get; set; } = string.Empty;
        public ValveAction Action { get; set; }
        public string Reason { get; set; } = string.Empty;
        public DateTime Timestamp { get; set; } = DateTime.UtcNow;
        public string IssuedBy { get; set; } = string.Empty; // System or User ID
    }

    public enum ValveAction
    {
        Open,
        Close,
        PartialOpen
    }
}
"@
Set-Content -Path $valveCommandPath -Value $valveCommandContent
Write-Host "  Created: ValveCommand.cs"

# Create Alert.cs
$alertPath = Join-Path -Path $modelsPath -ChildPath "Alert.cs"
$alertContent = @"
// WAT.IoT.Core/Models/Alert.cs
namespace WAT.IoT.Core.Models
{
    public class Alert
    {
        public string AlertId { get; set; } = Guid.NewGuid().ToString();
        public string DeviceId { get; set; } = string.Empty;
        public AlertType Type { get; set; }
        public AlertSeverity Severity { get; set; }
        public string Message { get; set; } = string.Empty;
        public DateTime Timestamp { get; set; } = DateTime.UtcNow;
        public bool Acknowledged { get; set; } = false;
        public DateTime? AcknowledgedTime { get; set; }
        public string? AcknowledgedBy { get; set; }
        public Dictionary<string, string> AdditionalInfo { get; set; } = new Dictionary<string, string>();
    }

    public enum AlertType
    {
        HighWaterLevel,
        LowWaterLevel,
        HighPressure,
        LowPressure,
        PoorWaterQuality,
        DeviceOffline,
        ValveFailure,
        BatteryLow,
        PowerOutage,
        UnauthorizedAccess,
        CommunicationFailure
    }

    public enum AlertSeverity
    {
        Information,
        Warning,
        Critical,
        Emergency
    }
}
"@
Set-Content -Path $alertPath -Value $alertContent
Write-Host "  Created: Alert.cs"

# Create WaterQualityReport.cs
$waterQualityReportPath = Join-Path -Path $modelsPath -ChildPath "WaterQualityReport.cs"
$waterQualityReportContent = @"
// WAT.IoT.Core/Models/WaterQualityReport.cs
namespace WAT.IoT.Core.Models
{
    public class WaterQualityReport
    {
        public string ReportId { get; set; } = Guid.NewGuid().ToString();
        public string DeviceId { get; set; } = string.Empty;
        public DateTime Timestamp { get; set; } = DateTime.UtcNow;
        public double OverallQualityScore { get; set; } // 0-100
        public double PH { get; set; }
        public double Turbidity { get; set; } // Nephelometric Turbidity Units (NTU)
        public double DissolvedOxygen { get; set; } // mg/L
        public double TotalDissolvedSolids { get; set; } // mg/L
        public double Conductivity { get; set; } // μS/cm
        public double Temperature { get; set; } // Celsius
        public double ChlorineLevels { get; set; } // mg/L
        public List<WaterContaminant> Contaminants { get; set; } = new List<WaterContaminant>();
        public bool MeetsRegulationStandards { get; set; } = true;
    }

    public class WaterContaminant
    {
        public string Name { get; set; } = string.Empty;
        public double Concentration { get; set; }
        public string Unit { get; set; } = string.Empty;
        public double MaxAllowedConcentration { get; set; }
        public bool ExceedsLimit => Concentration > MaxAllowedConcentration;
    }
}
"@
Set-Content -Path $waterQualityReportPath -Value $waterQualityReportContent
Write-Host "  Created: WaterQualityReport.cs"

# Create FloodEvent.cs
$floodEventPath = Join-Path -Path $modelsPath -ChildPath "FloodEvent.cs"
$floodEventContent = @"
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
"@
Set-Content -Path $floodEventPath -Value $floodEventContent
Write-Host "  Created: FloodEvent.cs"

Write-Host "Core projects created successfully" -ForegroundColor Green
#endregion

#region Create Devices Projects
Write-Host "Creating Devices projects..." -ForegroundColor Cyan

$projectPath = Join-Path -Path $outputPath -ChildPath "src\WAT.IoT.Devices"
$projectFile = Join-Path -Path $projectPath -ChildPath "WAT.IoT.Devices.csproj"

# Create Devices project if it doesn't exist
if (-not (Test-Path $projectFile)) {
    Set-Location $projectPath
    & dotnet new classlib
    
    # Update Devices project file with required packages
    $projectContent = @"
<Project Sdk="Microsoft.NET.Sdk">

  <PropertyGroup>
    <TargetFramework>net6.0</TargetFramework>
    <ImplicitUsings>enable</ImplicitUsings>
    <Nullable>enable</Nullable>
  </PropertyGroup>

  <ItemGroup>
    <PackageReference Include="Microsoft.Azure.Devices" Version="1.39.0" />
    <PackageReference Include="Microsoft.Azure.Devices.Client" Version="1.42.0" />
    <PackageReference Include="Microsoft.Azure.Devices.Provisioning.Client" Version="1.19.2" />
    <PackageReference Include="Microsoft.Azure.Devices.Provisioning.Transport.Mqtt" Version="1.18.2" />
    <PackageReference Include="Microsoft.Extensions.Logging.Abstractions" Version="6.0.0" />
    <PackageReference Include="Microsoft.Extensions.Options" Version="6.0.0" />
    <PackageReference Include="Newtonsoft.Json" Version="13.0.3" />
  </ItemGroup>

  <ItemGroup>
    <ProjectReference Include="..\WAT.IoT.Core\WAT.IoT.Core.csproj" />
  </ItemGroup>

</Project>
"@
    
    Set-Content -Path $projectFile -Value $projectContent
    Write-Host "  Created project: WAT.IoT.Devices"
    
    # Add project to solution
    Set-Location $outputPath
    & dotnet sln add "src\WAT.IoT.Devices\WAT.IoT.Devices.csproj"
}

# Create Configuration folder
$configPath = Join-Path -Path $projectPath -ChildPath "Configuration"

# Create IoTHubOptions.cs
$iotHubOptionsPath = Join-Path -Path $configPath -ChildPath "IoTHubOptions.cs"
$iotHubOptionsContent = @"
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
"@
Set-Content -Path $iotHubOptionsPath -Value $iotHubOptionsContent
Write-Host "  Created: IoTHubOptions.cs"

# Create Services folder
$servicesPath = Join-Path -Path $projectPath -ChildPath "Services"

# Create DeviceRegistryService.cs
$deviceRegistryServicePath = Join-Path -Path $servicesPath -ChildPath "DeviceRegistryService.cs"
$deviceRegistryServiceContent = @"
// WAT.IoT.Devices/Services/DeviceRegistryService.cs
using Microsoft.Azure.Devices;
using Microsoft.Azure.Devices.Shared;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using System.Collections.Concurrent;
using WAT.IoT.Core.Interfaces;
using WAT.IoT.Core.Models;
using WAT.IoT.Devices.Configuration;

namespace WAT.IoT.Devices.Services
{
    public class DeviceRegistryService : IDeviceRegistry
    {
        private readonly RegistryManager _registryManager;
        private readonly ILogger<DeviceRegistryService> _logger;
        private readonly IoTHubOptions _options;
        private readonly ConcurrentDictionary<string, DeviceInfo> _deviceCache = new ConcurrentDictionary<string, DeviceInfo>();

        public DeviceRegistryService(IOptions<IoTHubOptions> options, ILogger<DeviceRegistryService> logger)
        {
            _options = options.Value;
            _logger = logger;
            _registryManager = RegistryManager.CreateFromConnectionString(_options.ConnectionString);
        }

        public async Task<DeviceInfo> GetDeviceInfoAsync(string deviceId)
        {
            try
            {
                if (_deviceCache.TryGetValue(deviceId, out DeviceInfo? cachedDevice))
                {
                    return cachedDevice;
                }

                Device device = await _registryManager.GetDeviceAsync(deviceId);
                Twin twin = await _registryManager.GetTwinAsync(deviceId);

                if (device == null || twin == null)
                {
                    _logger.LogWarning("Device {DeviceId} not found", deviceId);
                    return new DeviceInfo { DeviceId = deviceId, IsActive = false };
                }

                var deviceInfo = MapToDeviceInfo(device, twin);
                _deviceCache[deviceId] = deviceInfo;
                return deviceInfo;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting device {DeviceId}", deviceId);
                throw;
            }
        }

        public async Task<IEnumerable<DeviceInfo>> GetAllDevicesAsync()
        {
            var devices = new List<DeviceInfo>();
            try
            {
                var query = _registryManager.CreateQuery("SELECT * FROM devices", 100);
                
                while (query.HasMoreResults)
                {
                    var page = await query.GetNextAsTwinAsync();
                    foreach (var twin in page)
                    {
                        var device = await _registryManager.GetDeviceAsync(twin.DeviceId);
                        var deviceInfo = MapToDeviceInfo(device, twin);
                        devices.Add(deviceInfo);
                        _deviceCache[twin.DeviceId] = deviceInfo;
                    }
                }

                return devices;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting all devices");
                throw;
            }
        }

        public async Task<IEnumerable<DeviceInfo>> GetDevicesByLocationAsync(string location)
        {
            var devices = new List<DeviceInfo>();
            try
            {
                var query = _registryManager.CreateQuery($"SELECT * FROM devices WHERE tags.location = '{location}'", 100);
                
                while (query.HasMoreResults)
                {
                    var page = await query.GetNextAsTwinAsync();
                    foreach (var twin in page)
                    {
                        var device = await _registryManager.GetDeviceAsync(twin.DeviceId);
                        var deviceInfo = MapToDeviceInfo(device, twin);
                        devices.Add(deviceInfo);
                        _deviceCache[twin.DeviceId] = deviceInfo;
                    }
                }

                return devices;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting devices by location {Location}", location);
                throw;
            }
        }

        public async Task<bool> AddDeviceAsync(DeviceInfo device)
        {
            try
            {
                var azureDevice = new Device(device.DeviceId);
                azureDevice.Status = device.IsActive ? DeviceStatus.Enabled : DeviceStatus.Disabled;

                Device createdDevice = await _registryManager.AddDeviceAsync(azureDevice);
                
                var twin = new Twin(device.DeviceId);
                twin.Tags["deviceType"] = device.DeviceType;
                twin.Tags["location"] = device.Location;
                twin.Tags["connectionType"] = device.ConnectionType;
                twin.Properties.Reported["firmwareVersion"] = device.FirmwareVersion;
                
                foreach (var tag in device.Tags)
                {
                    twin.Tags[tag.Key] = tag.Value;
                }

                await _registryManager.UpdateTwinAsync(device.DeviceId, twin, twin.ETag);
                
                _deviceCache[device.DeviceId] = device;
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error adding device {DeviceId}", device.DeviceId);
                return false;
            }
        }

        public async Task<bool> UpdateDeviceAsync(DeviceInfo device)
        {
            try
            {
                var existingDevice = await _registryManager.GetDeviceAsync(device.DeviceId);
                if (existingDevice == null)
                {
                    _logger.LogWarning("Device {DeviceId} not found for update", device.DeviceId);
                    return false;
                }

                existingDevice.Status = device.IsActive ? DeviceStatus.Enabled : DeviceStatus.Disabled;
                await _registryManager.UpdateDeviceAsync(existingDevice);

                var twin = await _registryManager.GetTwinAsync(device.DeviceId);
                twin.Tags["deviceType"] = device.DeviceType;
                twin.Tags["location"] = device.Location;
                twin.Tags["connectionType"] = device.ConnectionType;
                
                foreach (var tag in device.Tags)
                {
                   twin.Tags[tag.Key] = tag.Value;
                }

                await _registryManager.UpdateTwinAsync(device.DeviceId, twin, twin.ETag);
                
                _deviceCache[device.DeviceId] = device;
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating device {DeviceId}", device.DeviceId);
                return false;
            }
        }

        public async Task<bool> DeleteDeviceAsync(string deviceId)
        {
            try
            {
                await _registryManager.RemoveDeviceAsync(deviceId);
                _deviceCache.TryRemove(deviceId, out _);
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting device {DeviceId}", deviceId);
                return false;
            }
        }

        public async Task<bool> IsDeviceRegisteredAsync(string deviceId)
        {
            try
            {
                if (_deviceCache.TryGetValue(deviceId, out DeviceInfo? _))
                {
                    return true;
                }

                var device = await _registryManager.GetDeviceAsync(deviceId);
                return device != null;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error checking if device {DeviceId} is registered", deviceId);
                return false;
            }
        }

        private DeviceInfo MapToDeviceInfo(Device device, Twin twin)
        {
            var deviceInfo = new DeviceInfo
            {
                DeviceId = device.Id,
                IsActive = device.Status == DeviceStatus.Enabled,
                LastActivityTime = device.LastActivityTime ?? DateTime.UtcNow
            };

            if (twin.Tags.Contains("deviceType"))
            {
                deviceInfo.DeviceType = twin.Tags["deviceType"];
            }

            if (twin.Tags.Contains("location"))
            {
                deviceInfo.Location = twin.Tags["location"];
            }

            if (twin.Tags.Contains("connectionType"))
            {
                deviceInfo.ConnectionType = twin.Tags["connectionType"];
            }

            if (twin.Properties.Reported.Contains("firmwareVersion"))
            {
                deviceInfo.FirmwareVersion = twin.Properties.Reported["firmwareVersion"];
            }

            foreach (var tag in twin.Tags)
            {
                if (tag.Key != "deviceType" && tag.Key != "location" && tag.Key != "connectionType")
                {
                    deviceInfo.Tags[tag.Key] = tag.Value;
                }
            }

            return deviceInfo;
        }
    }
}
"@
Set-Content -Path $deviceRegistryServicePath -Value $deviceRegistryServiceContent
Write-Host "  Created: DeviceRegistryService.cs"

# Create DeviceCommunicationService.cs
$deviceCommunicationServicePath = Join-Path -Path $servicesPath -ChildPath "DeviceCommunicationService.cs"
$deviceCommunicationServiceContent = @"
// WAT.IoT.Devices/Services/DeviceCommunicationService.cs
using Microsoft.Azure.Devices;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Newtonsoft.Json;
using System.Text;
using WAT.IoT.Core.Interfaces;
using WAT.IoT.Core.Models;
using WAT.IoT.Devices.Configuration;

namespace WAT.IoT.Devices.Services
{
    public class DeviceCommunicationService : IDeviceCommunication
    {
        private readonly ServiceClient _serviceClient;
        private readonly ILogger<DeviceCommunicationService> _logger;
        private readonly IoTHubOptions _options;
        private readonly RegistryManager _registryManager;
        private readonly Dictionary<string, DeviceConnectionStatus> _connectionStatusCache = new Dictionary<string, DeviceConnectionStatus>();
        private readonly Dictionary<string, TelemetryReading> _latestTelemetryCache = new Dictionary<string, TelemetryReading>();

        public DeviceCommunicationService(IOptions<IoTHubOptions> options, ILogger<DeviceCommunicationService> logger)
        {
            _options = options.Value;
            _logger = logger;
            _serviceClient = ServiceClient.CreateFromConnectionString(_options.ConnectionString);
            _registryManager = RegistryManager.CreateFromConnectionString(_options.ConnectionString);
        }

        public async Task<bool> SendCommandAsync(string deviceId, ValveCommand command)
        {
            try
            {
                var methodInvocation = new CloudToDeviceMethod("ValveOperation")
                {
                    ResponseTimeout = TimeSpan.FromSeconds(_options.DefaultTimeoutSeconds)
                };

                string commandJson = JsonConvert.SerializeObject(command);
                methodInvocation.SetPayloadJson(commandJson);

                _logger.LogInformation("Sending valve command to device {DeviceId}: {Action}", 
                    deviceId, command.Action);

                var result = await _serviceClient.InvokeDeviceMethodAsync(deviceId, methodInvocation);
                
                if (result.Status == 200)
                {
                    _logger.LogInformation("Command sent successfully to device {DeviceId}", deviceId);
                    return true;
                }
                else
                {
                    _logger.LogWarning("Failed to send command to device {DeviceId}. Status: {Status}", 
                        deviceId, result.Status);
                    return false;
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error sending command to device {DeviceId}", deviceId);
                return false;
            }
        }

        public async Task<bool> SendCommandBatchAsync(IEnumerable<ValveCommand> commands)
        {
            bool allSucceeded = true;
            foreach (var command in commands)
            {
                bool success = await SendCommandAsync(command.DeviceId, command);
                if (!success)
                {
                    allSucceeded = false;
                    _logger.LogWarning("Failed to send command to device {DeviceId}", command.DeviceId);
                }
            }
            return allSucceeded;
        }

        public async Task<TelemetryReading?> GetLatestTelemetryAsync(string deviceId)
        {
            try
            {
                if (_latestTelemetryCache.TryGetValue(deviceId, out TelemetryReading? cachedReading))
                {
                    // If cache is less than 5 minutes old, return it
                    if (DateTime.UtcNow.Subtract(cachedReading.Timestamp).TotalMinutes < 5)
                    {
                        return cachedReading;
                    }
                }

                // Send a direct method to get latest telemetry
                var methodInvocation = new CloudToDeviceMethod("GetLatestTelemetry")
                {
                    ResponseTimeout = TimeSpan.FromSeconds(_options.DefaultTimeoutSeconds)
                };

                var result = await _serviceClient.InvokeDeviceMethodAsync(deviceId, methodInvocation);
                
                if (result.Status == 200)
                {
                    var telemetry = JsonConvert.DeserializeObject<TelemetryReading>(result.GetPayloadAsJson());
                    if (telemetry != null)
                    {
                        _latestTelemetryCache[deviceId] = telemetry;
                        return telemetry;
                    }
                }
                
                _logger.LogWarning("Failed to get latest telemetry for device {DeviceId}", deviceId);
                return null;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting latest telemetry for device {DeviceId}", deviceId);
                return null;
            }
        }

        public async Task<bool> IsDeviceOnlineAsync(string deviceId)
        {
            var status = await GetConnectionStatusAsync(deviceId);
            return status == DeviceConnectionStatus.Online;
        }

        public async Task<DeviceConnectionStatus> GetConnectionStatusAsync(string deviceId)
        {
            try
            {
                if (_connectionStatusCache.TryGetValue(deviceId, out DeviceConnectionStatus cachedStatus))
                {
                    return cachedStatus;
                }

                var twin = await _registryManager.GetTwinAsync(deviceId);
                if (twin == null)
                {
                    _logger.LogWarning("Device {DeviceId} not found", deviceId);
                    return DeviceConnectionStatus.Unknown;
                }

                // Check connection state from reported properties
                if (twin.ConnectionState == Microsoft.Azure.Devices.Shared.ConnectionState.Connected)
                {
                    _connectionStatusCache[deviceId] = DeviceConnectionStatus.Online;
                    return DeviceConnectionStatus.Online;
                }
                else if (twin.ConnectionState == Microsoft.Azure.Devices.Shared.ConnectionState.Disconnected)
                {
                    _connectionStatusCache[deviceId] = DeviceConnectionStatus.Offline;
                    return DeviceConnectionStatus.Offline;
                }

                // If last activity time is recent (within 15 minutes), consider it online
                if (twin.LastActivityTime.HasValue && 
                    DateTime.UtcNow.Subtract(twin.LastActivityTime.Value).TotalMinutes < 15)
                {
                    _connectionStatusCache[deviceId] = DeviceConnectionStatus.Online;
                    return DeviceConnectionStatus.Online;
                }

                // Try sending a ping to check if device is responsive
                try
                {
                    var methodInvocation = new CloudToDeviceMethod("Ping")
                    {
                        ResponseTimeout = TimeSpan.FromSeconds(5) // Short timeout for ping
                    };

                    var result = await _serviceClient.InvokeDeviceMethodAsync(deviceId, methodInvocation);
                    if (result.Status == 200)
                    {
                        _connectionStatusCache[deviceId] = DeviceConnectionStatus.Online;
                        return DeviceConnectionStatus.Online;
                    }
                }
                catch
                {
                    // If ping fails, device is offline
                    _connectionStatusCache[deviceId] = DeviceConnectionStatus.Offline;
                    return DeviceConnectionStatus.Offline;
                }

                _connectionStatusCache[deviceId] = DeviceConnectionStatus.Unknown;
                return DeviceConnectionStatus.Unknown;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error checking connection status for device {DeviceId}", deviceId);
                return DeviceConnectionStatus.Unknown;
            }
        }

        public async Task UpdateConnectionStatusCacheAsync(string deviceId, DeviceConnectionStatus status)
        {
            _connectionStatusCache[deviceId] = status;
            await Task.CompletedTask;
        }

        public async Task UpdateTelemetryCacheAsync(TelemetryReading reading)
        {
            _latestTelemetryCache[reading.DeviceId] = reading;
            await Task.CompletedTask;
        }
    }
}
"@
Set-Content -Path $deviceCommunicationServicePath -Value $deviceCommunicationServiceContent
Write-Host "  Created: DeviceCommunicationService.cs"

# Create Helpers folder
$helpersPath = Join-Path -Path $projectPath -ChildPath "Helpers"

# Create DeviceSecurityHelper.cs
$deviceSecurityHelperPath = Join-Path -Path $helpersPath -ChildPath "DeviceSecurityHelper.cs"
$deviceSecurityHelperContent = @"
// WAT.IoT.Devices/Helpers/DeviceSecurityHelper.cs
using Microsoft.Azure.Devices.Client;
using Microsoft.Azure.Devices.Provisioning.Client;
using Microsoft.Azure.Devices.Provisioning.Client.Transport;
using Microsoft.Azure.Devices.Shared;
using Microsoft.Extensions.Logging;
using System.Security.Cryptography;
using System.Text;

namespace WAT.IoT.Devices.Helpers
{
    public static class DeviceSecurityHelper
    {
        public static string ComputeDerivedSymmetricKey(string masterKey, string deviceId)
        {
            using (var hmac = new HMACSHA256(Convert.FromBase64String(masterKey)))
            {
                return Convert.ToBase64String(hmac.ComputeHash(Encoding.UTF8.GetBytes(deviceId)));
            }
        }

        public static async Task<DeviceRegistrationResult> RegisterDeviceWithDpsAsync(
            string idScope,
            string deviceId,
            string primaryKey,
            string globalEndpoint,
            ILogger logger)
        {
            try
            {
                logger.LogInformation("Registering device {DeviceId} with DPS", deviceId);

                // Create a security provider using symmetric key for authentication
                using var securityProvider = new SecurityProviderSymmetricKey(
                    deviceId,
                    primaryKey,
                    null);

                // Create the transport (MQTT) for communicating with DPS
                using var transport = new ProvisioningTransportHandlerMqtt();

                // Create the provisioning client
                var provClient = ProvisioningDeviceClient.Create(
                    globalEndpoint,
                    idScope,
                    securityProvider,
                    transport);

                // Register the device
                var result = await provClient.RegisterAsync();

                logger.LogInformation("Registration result: {Status}", result.Status);

                if (result.Status == ProvisioningRegistrationStatusType.Assigned)
                {
                    logger.LogInformation("Device {DeviceId} registered to hub {Hub} with ID {AssignedId}",
                        deviceId, result.AssignedHub, result.DeviceId);
                }
                else
                {
                    logger.LogWarning("Device {DeviceId} failed to register. Status: {Status}",
                        deviceId, result.Status);
                }

                return result;
            }
            catch (Exception ex)
            {
                logger.LogError(ex, "Error registering device {DeviceId} with DPS", deviceId);
                throw;
            }
        }

        public static async Task<DeviceClient> CreateDeviceClientFromDpsRegistrationAsync(
            DeviceRegistrationResult registrationResult,
            ILogger logger)
        {
            if (registrationResult.Status != ProvisioningRegistrationStatusType.Assigned)
            {
                logger.LogError("Cannot create device client because device is not assigned");
                throw new InvalidOperationException("Device registration is not in 'Assigned' state");
            }

            // Create the device client from the registration result
            var auth = new DeviceAuthenticationWithRegistrySymmetricKey(
                registrationResult.DeviceId,
                registrationResult.ProvisioningDeviceClient?.GetSymmetricKey());

            var deviceClient = DeviceClient.Create(
                registrationResult.AssignedHub,
                auth,
                TransportType.Mqtt);

            logger.LogInformation("Created device client for device {DeviceId}", registrationResult.DeviceId);
            return deviceClient;
        }

        public static async Task UpdateDeviceTwinAsync(DeviceClient deviceClient, Dictionary<string, object> reportedProperties, ILogger logger)
        {
            try
            {
                var twin = await deviceClient.GetTwinAsync();
                var patch = new TwinCollection();

                foreach (var prop in reportedProperties)
                {
                    patch[prop.Key] = prop.Value;
                }

                await deviceClient.UpdateReportedPropertiesAsync(patch);
                logger.LogInformation("Updated device twin properties");
            }
            catch (Exception ex)
            {
                logger.LogError(ex, "Error updating device twin properties");
                throw;
            }
        }
    }
}
"@
Set-Content -Path $deviceSecurityHelperPath -Value $deviceSecurityHelperContent
Write-Host "  Created: DeviceSecurityHelper.cs"

Write-Host "Devices projects created successfully" -ForegroundColor Green
#endregion

#region Create Processing Projects
Write-Host "Creating Processing projects..." -ForegroundColor Cyan

$projectPath = Join-Path -Path $outputPath -ChildPath "src\WAT.IoT.Processing"
$projectFile = Join-Path -Path $projectPath -ChildPath "WAT.IoT.Processing.csproj"

# Create Processing project if it doesn't exist
if (-not (Test-Path $projectFile)) {
    Set-Location $projectPath
    & dotnet new classlib
    
    # Update Processing project file with required packages
    $projectContent = @"
<Project Sdk="Microsoft.NET.Sdk">

  <PropertyGroup>
    <TargetFramework>net6.0</TargetFramework>
    <ImplicitUsings>enable</ImplicitUsings>
    <Nullable>enable</Nullable>
  </PropertyGroup>

  <ItemGroup>
    <PackageReference Include="Azure.Messaging.EventHubs" Version="5.9.2" />
    <PackageReference Include="Azure.Messaging.EventHubs.Processor" Version="5.9.2" />
    <PackageReference Include="Azure.Storage.Blobs" Version="12.17.0" />
    <PackageReference Include="Microsoft.Azure.Cosmos" Version="3.35.3" />
    <PackageReference Include="Microsoft.Azure.Devices" Version="1.39.0" />
    <PackageReference Include="Microsoft.Extensions.Logging.Abstractions" Version="6.0.0" />
    <PackageReference Include="Microsoft.Extensions.Options" Version="6.0.0" />
    <PackageReference Include="Newtonsoft.Json" Version="13.0.3" />
  </ItemGroup>

  <ItemGroup>
    <ProjectReference Include="..\WAT.IoT.Core\WAT.IoT.Core.csproj" />
  </ItemGroup>

</Project>
"@
    
    Set-Content -Path $projectFile -Value $projectContent
    Write-Host "  Created project: WAT.IoT.Processing"
    
    # Add project to solution
    Set-Location $outputPath
    & dotnet sln add "src\WAT.IoT.Processing\WAT.IoT.Processing.csproj"
}

# Create Configuration folder
$configPath = Join-Path -Path $projectPath -ChildPath "Configuration"

# Create ProcessingOptions.cs
$processingOptionsPath = Join-Path -Path $configPath -ChildPath "ProcessingOptions.cs"
$processingOptionsContent = @"
// WAT.IoT.Processing/Configuration/ProcessingOptions.cs
namespace WAT.IoT.Processing.Configuration
{
    public class ProcessingOptions
    {
        public string EventHubConnectionString { get; set; } = string.Empty;
        public string EventHubName { get; set; } = "telemetry";
        public string ConsumerGroup { get; set; } = "$Default";
        public string CosmosDbConnectionString { get; set; } = string.Empty;
        public string CosmosDbDatabaseName { get; set; } = "WATOperationalData";
        public string TelemetryContainerName { get; set; } = "telemetry";
        public string EventsContainerName { get; set; } = "events";
        public string WaterQualityContainerName { get; set; } = "waterQuality";
        public string StorageConnectionString { get; set; } = string.Empty;
        public string StorageContainerName { get; set; } = "checkpoints";
        public int TelemetryProcessingBatchSize { get; set; } = 100;
        public int MaxConcurrentProcessingTasks { get; set; } = 10;
        public int AlertThresholdPeriodMinutes { get; set; } = 10;
        public bool EnableAnomalyDetection { get; set; } = true;
        public double HighWaterLevelThreshold { get; set; } = 80.0;
        public double LowWaterLevelThreshold { get; set; } = 20.0;
        public double HighPressureThreshold { get; set; } = 100.0;
        public double LowPressureThreshold { get; set; } = 10.0;
        public double WaterQualityThreshold { get; set; } = 50.0;
        public double BatteryLowThreshold { get; set; } = 15.0;
    }
}
"@
Set-Content -Path $processingOptionsPath -Value $processingOptionsContent
Write-Host "  Created: ProcessingOptions.cs"

# Create Services folder
$servicesPath = Join-Path -Path $projectPath -ChildPath "Services"

# Create TelemetryProcessorService.cs
$telemetryProcessorServicePath = Join-Path -Path $servicesPath -ChildPath "TelemetryProcessorService.cs"
$telemetryProcessorServiceContent = @"
// WAT.IoT.Processing/Services/TelemetryProcessorService.cs
using Azure.Messaging.EventHubs;
using Azure.Messaging.EventHubs.Consumer;
using Azure.Messaging.EventHubs.Processor;
using Azure.Storage.Blobs;
using Microsoft.Azure.Cosmos;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Newtonsoft.Json;
using System.Text;
using WAT.IoT.Core.Interfaces;
using WAT.IoT.Core.Models;
using WAT.IoT.Processing.Configuration;

namespace WAT.IoT.Processing.Services
{
    public class TelemetryProcessorService : ITelemetryProcessor, IAsyncDisposable
    {
        private readonly ILogger<TelemetryProcessorService> _logger;
        private readonly ProcessingOptions _options;
        private readonly CosmosClient _cosmosClient;
        private readonly Container _telemetryContainer;
        private readonly Container _waterQualityContainer;
        private readonly IAlertManager _alertManager;
        private readonly IDeviceCommunication _deviceCommunication;
        private readonly Dictionary<string, List<TelemetryReading>> _telemetryCache = new Dictionary<string, List<TelemetryReading>>();
        private readonly SemaphoreSlim _cacheLock = new SemaphoreSlim(1, 1);
        private EventProcessorClient? _processorClient;
        private bool _isStarted = false;
        private readonly Dictionary<string, DateTime> _lastAlertTimeByDevice = new Dictionary<string, DateTime>();

        public TelemetryProcessorService(
            IOptions<ProcessingOptions> options, 
            ILogger<TelemetryProcessorService> logger,
            IAlertManager alertManager,
            IDeviceCommunication deviceCommunication)
        {
            _logger = logger;
            _options = options.Value;
            _alertManager = alertManager;
            _deviceCommunication = deviceCommunication;

            // Initialize Cosmos DB client
            _cosmosClient = new CosmosClient(_options.CosmosDbConnectionString);
            _telemetryContainer = _cosmosClient.GetContainer(_options.CosmosDbDatabaseName, _options.TelemetryContainerName);
            _waterQualityContainer = _cosmosClient.GetContainer(_options.CosmosDbDatabaseName, _options.WaterQualityContainerName);
        }

        public async Task StartProcessingAsync()
        {
            if (_isStarted)
            {
                _logger.LogWarning("Telemetry processor is already running");
                return;
            }

            try
            {
                // Create a blob container client for the checkpoint store
                var storageClient = new BlobContainerClient(_options.StorageConnectionString, _options.StorageContainerName);
                await storageClient.CreateIfNotExistsAsync();

                // Create an event processor client to process events from the event hub
                _processorClient = new EventProcessorClient(
                    storageClient,
                    _options.ConsumerGroup,
                    _options.EventHubConnectionString,
                    _options.EventHubName);

                // Register handlers for processing events and handling errors
                _processorClient.ProcessEventAsync += ProcessEventHandler;
                _processorClient.ProcessErrorAsync += ProcessErrorHandler;

                // Start the processing
                _processorClient.StartProcessing();
                _isStarted = true;

                _logger.LogInformation("Telemetry processor started");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error starting telemetry processor");
                throw;
            }
        }

        public async Task StopProcessingAsync()
        {
            if (!_isStarted || _processorClient == null)
            {
                _logger.LogWarning("Telemetry processor is not running");
                return;
            }

            try
            {
                // Stop the processor client
                await _processorClient.StopProcessingAsync();
                _processorClient.ProcessEventAsync -= ProcessEventHandler;
                _processorClient.ProcessErrorAsync -= ProcessErrorHandler;
                _isStarted = false;

                _logger.LogInformation("Telemetry processor stopped");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error stopping telemetry processor");
                throw;
            }
        }

        public async Task ProcessTelemetryAsync(TelemetryReading reading)
        {
            try
            {
                _logger.LogDebug("Processing telemetry from device {DeviceId}", reading.DeviceId);

                // Store the telemetry in Cosmos DB
                await _telemetryContainer.CreateItemAsync(reading, new PartitionKey(reading.DeviceId));

                // Update the device's last telemetry in the device communication service
                await _deviceCommunication.UpdateTelemetryCacheAsync(reading);

                // Check if any alerts should be raised
                await CheckForAlertsAsync(reading);

                // Add to cache for history
                await AddToTelemetryCacheAsync(reading);

                _logger.LogDebug("Telemetry from device {DeviceId} processed successfully", reading.DeviceId);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error processing telemetry from device {DeviceId}", reading.DeviceId);
            }
        }

        public async Task ProcessBatchTelemetryAsync(IEnumerable<TelemetryReading> readings)
        {
            var tasks = new List<Task>();
            foreach (var reading in readings)
            {
                tasks.Add(ProcessTelemetryAsync(reading));
                
                // Throttle the number of concurrent tasks
                if (tasks.Count >= _options.MaxConcurrentProcessingTasks)
                {
                    await Task.WhenAny(tasks);
                    tasks.RemoveAll(t => t.IsCompleted);
                }
            }

            // Wait for remaining tasks to complete
            await Task.WhenAll(tasks);
        }

        public async Task<IEnumerable<TelemetryReading>> GetTelemetryHistoryAsync(string deviceId, DateTime startTime, DateTime endTime)
        {
            try
            {
                // Check cache first for recent data
                var cachedReadings = await GetCachedTelemetryAsync(deviceId, startTime, endTime);
                if (cachedReadings.Any())
                {
                    return cachedReadings;
                }

                // Query Cosmos DB for historical data
                string query = $"SELECT * FROM c WHERE c.deviceId = @deviceId AND c.timestamp >= @startTime AND c.timestamp <= @endTime ORDER BY c.timestamp DESC";
                var queryDef = new QueryDefinition(query)
                    .WithParameter("@deviceId", deviceId)
                    .WithParameter("@startTime", startTime.ToString("o"))
                    .WithParameter("@endTime", endTime.ToString("o"));

                var results = new List<TelemetryReading>();
                var iterator = _telemetryContainer.GetItemQueryIterator<TelemetryReading>(queryDef);

                while (iterator.HasMoreResults)
                {
                    var response = await iterator.ReadNextAsync();
                    results.AddRange(response);
                }

                return results;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting telemetry history for device {DeviceId}", deviceId);
                return Enumerable.Empty<TelemetryReading>();
            }
        }

        public async Task<WaterQualityReport> GenerateWaterQualityReportAsync(string deviceId)
        {
            try
            {
                // Get recent telemetry (last 24 hours)
                var endTime = DateTime.UtcNow;
                var startTime = endTime.AddHours(-24);

                var telemetryHistory = await GetTelemetryHistoryAsync(deviceId, startTime, endTime);

                if (!telemetryHistory.Any())
                {
                    throw new InvalidOperationException($"No recent telemetry found for device {deviceId}");
                }

                // Calculate average water quality metrics
                var avgQuality = telemetryHistory.Average(t => t.WaterQuality);
                var latestReading = telemetryHistory.OrderByDescending(t => t.Timestamp).First();

                // Generate a water quality report
                var report = new WaterQualityReport
                {
                    DeviceId = deviceId,
                    Timestamp = DateTime.UtcNow,
                    OverallQualityScore = avgQuality,
                    PH = 7.2, // Mock value, should be derived from actual sensors
                    Turbidity = 0.5, // Mock value, should be derived from actual sensors
                    DissolvedOxygen = 8.5, // Mock value, should be derived from actual sensors
                    TotalDissolvedSolids = 150, // Mock value, should be derived from actual sensors
                    Conductivity = 320, // Mock value, should be derived from actual sensors
                    Temperature = latestReading.Temperature,
                    ChlorineLevels = 1.2, // Mock value, should be derived from actual sensors
                    MeetsRegulationStandards = avgQuality >= _options.WaterQualityThreshold
                };

                // Add some contaminants based on quality score
                if (avgQuality < 95)
                {
                    report.Contaminants.Add(new WaterContaminant
                    {
                        Name = "Total Coliform",
                        Concentration = 2.5,
                        Unit = "cfu/100mL",
                        MaxAllowedConcentration = 5.0
                    });
                }

                if (avgQuality < 85)
                {
                    report.Contaminants.Add(new WaterContaminant
                    {
                        Name = "Lead",
                        Concentration = 0.011,
                        Unit = "mg/L",
                        MaxAllowedConcentration = 0.015
                    });
                }

                if (avgQuality < 70)
                {
                    report.Contaminants.Add(new WaterContaminant
                    {
                        Name = "Nitrates",
                        Concentration = 11.5,
                        Unit = "mg/L",
                        MaxAllowedConcentration = 10.0
                    });
                }

                // Save the report to Cosmos DB
                await _waterQualityContainer.CreateItemAsync(report, new PartitionKey(deviceId));

                return report;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error generating water quality report for device {DeviceId}", deviceId);
                throw;
            }
        }

        private async Task ProcessEventHandler(ProcessEventArgs args)
        {
            try
            {
                // Read the telemetry data from the event
                var messageBody = Encoding.UTF8.GetString(args.Data.Body.ToArray());
                var telemetry = JsonConvert.DeserializeObject<TelemetryReading>(messageBody);

                if (telemetry != null)
                {
                    // Process the telemetry reading
                    await ProcessTelemetryAsync(telemetry);
                }
                else
                {
                    _logger.LogWarning("Received null or invalid telemetry data");
                }

                // Update the checkpoint
                await args.UpdateCheckpointAsync(args.CancellationToken);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in telemetry event handler");
            }
        }

        private Task ProcessErrorHandler(ProcessErrorEventArgs args)
        {
            _logger.LogError(args.Exception, "Error in event processor: {ErrorMessage}", args.Exception.Message);
            return Task.CompletedTask;
        }

        private async Task CheckForAlertsAsync(TelemetryReading reading)
        {
            try
            {
                // Check if we've recently sent an alert for this device to avoid alert floods
                if (_lastAlertTimeByDevice.TryGetValue(reading.DeviceId, out DateTime lastAlertTime))
                {
                    var timeSinceLastAlert = DateTime.UtcNow - lastAlertTime;
                    if (timeSinceLastAlert.TotalMinutes < _options.AlertThresholdPeriodMinutes)
                    {
                        // Skip alert checking if too recent
                        return;
                    }
                }

                var alerts = new List<Alert>();

                // Check water level
                if (reading.WaterLevelStatus == WaterLevelStatus.High || reading.WaterLevelStatus == WaterLevelStatus.Critical)
                {
                    alerts.Add(new Alert
                    {
                        DeviceId = reading.DeviceId,
                        Type = AlertType.HighWaterLevel,
                        Severity = reading.WaterLevelStatus == WaterLevelStatus.Critical ? 
                            AlertSeverity.Emergency : AlertSeverity.Warning,
                        Message = $"High water level detected: {reading.WaterLevelStatus}",
                        Timestamp = DateTime.UtcNow
                    });
                }
                else if (reading.WaterLevelStatus == WaterLevelStatus.Low)
                {
                    alerts.Add(new Alert
                    {
                        DeviceId = reading.DeviceId,
                        Type = AlertType.LowWaterLevel,
                        Severity = AlertSeverity.Warning,
                        Message = "Low water level detected",
                        Timestamp = DateTime.UtcNow
                    });
                }

                // Check water pressure
                if (reading.WaterPressure > _options.HighPressureThreshold)
                {
                    alerts.Add(new Alert
                    {
                        DeviceId = reading.DeviceId,
                        Type = AlertType.HighPressure,
                        Severity = AlertSeverity.Warning,
                        Message = $"High water pressure detected: {reading.WaterPressure} Pa",
                        Timestamp = DateTime.UtcNow
                    });
                }
                else if (reading.WaterPressure < _options.LowPressureThreshold)
                {
                    alerts.Add(new Alert
                    {
                        DeviceId = reading.DeviceId,
                        Type = AlertType.LowPressure,
                        Severity = AlertSeverity.Warning,
                        Message = $"Low water pressure detected: {reading.WaterPressure} Pa",
                        Timestamp = DateTime.UtcNow
                    });
                }

                // Check water quality
                if (reading.WaterQuality < _options.WaterQualityThreshold)
                {
                    alerts.Add(new Alert
                    {
                        DeviceId = reading.DeviceId,
                        Type = AlertType.PoorWaterQuality,
                        Severity = reading.WaterQuality < _options.WaterQualityThreshold / 2 ? 
                            AlertSeverity.Critical : AlertSeverity.Warning,
                        Message = $"Poor water quality detected: {reading.WaterQuality}",
                        Timestamp = DateTime.UtcNow,
                        AdditionalInfo = new Dictionary<string, string>
                        {
                            { "QualityScore", reading.WaterQuality.ToString() },
                            { "Threshold", _options.WaterQualityThreshold.ToString() }
                        }
                    });
                }

                // Check battery level
                if (reading.BatteryLevel < _options.BatteryLowThreshold)
                {
                    alerts.Add(new Alert
                    {
                        DeviceId = reading.DeviceId,
                        Type = AlertType.BatteryLow,
                        Severity = reading.BatteryLevel < _options.BatteryLowThreshold / 2 ? 
                            AlertSeverity.Critical : AlertSeverity.Warning,
                        Message = $"Low battery level detected: {reading.BatteryLevel}%",
                        Timestamp = DateTime.UtcNow
                    });
                }

                // Submit all alerts
                foreach (var alert in alerts)
                {
                    await _alertManager.CreateAlertAsync(alert);
                }

                // If any alerts were raised, update the last alert time
                if (alerts.Any())
                {
                    _lastAlertTimeByDevice[reading.DeviceId] = DateTime.UtcNow;
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error checking for alerts from device {DeviceId}", reading.DeviceId);
            }
        }

        private async Task AddToTelemetryCacheAsync(TelemetryReading reading)
        {
            try
            {
                await _cacheLock.WaitAsync();
                
                if (!_telemetryCache.TryGetValue(reading.DeviceId, out var deviceReadings))
                {
                    deviceReadings = new List<TelemetryReading>();
                    _telemetryCache[reading.DeviceId] = deviceReadings;
                }

                // Add the new reading
                deviceReadings.Add(reading);

                // Keep only the last 100 readings per device
                if (deviceReadings.Count > 100)
                {
                    _telemetryCache[reading.DeviceId] = deviceReadings
                        .OrderByDescending(r => r.Timestamp)
                        .Take(100)
                        .ToList();
                }
            }
            finally
            {
                _cacheLock.Release();
            }
        }

        private async Task<IEnumerable<TelemetryReading>> GetCachedTelemetryAsync(
            string deviceId, DateTime startTime, DateTime endTime)
        {
            try
            {
                await _cacheLock.WaitAsync();
                
                if (!_telemetryCache.TryGetValue(deviceId, out var deviceReadings))
                {
                    return Enumerable.Empty<TelemetryReading>();
                }

                return deviceReadings
                    .Where(r => r.Timestamp >= startTime && r.Timestamp <= endTime)
                    .OrderByDescending(r => r.Timestamp)
                    .ToList();
            }
            finally
            {
                _cacheLock.Release();
            }
        }

        public async ValueTask DisposeAsync()
        {
            if (_isStarted && _processorClient != null)
            {
                await StopProcessingAsync();
            }

            _cosmosClient?.Dispose();
            _cacheLock?.Dispose();
        }
    }
}
"@
Set-Content -Path $telemetryProcessorServicePath -Value $telemetryProcessorServiceContent
Write-Host "  Created: TelemetryProcessorService.cs"

# Create AlertManagerService.cs
$alertManagerServicePath = Join-Path -Path $servicesPath -ChildPath "AlertManagerService.cs"
$alertManagerServiceContent = @"
// WAT.IoT.Processing/Services/AlertManagerService.cs
using Microsoft.Azure.Cosmos;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using WAT.IoT.Core.Interfaces;
using WAT.IoT.Core.Models;
using WAT.IoT.Processing.Configuration;

namespace WAT.IoT.Processing.Services
{
    public class AlertManagerService : IAlertManager
    {
        private readonly ILogger<AlertManagerService> _logger;
        private readonly ProcessingOptions _options;
        private readonly CosmosClient _cosmosClient;
        private readonly Container _eventsContainer;

        public AlertManagerService(
            IOptions<ProcessingOptions> options,
            ILogger<AlertManagerService> logger)
        {
            _logger = logger;
            _options = options.Value;

            // Initialize Cosmos DB client
            _cosmosClient = new CosmosClient(_options.CosmosDbConnectionString);
            _eventsContainer = _cosmosClient.GetContainer(_options.CosmosDbDatabaseName, _options.EventsContainerName);
        }

        public async Task<string> CreateAlertAsync(Alert alert)
        {
            try
            {
                _logger.LogInformation("Creating alert: {AlertType} for device {DeviceId}", alert.Type, alert.DeviceId);
                
                // Generate a new alert ID if not provided
                if (string.IsNullOrEmpty(alert.AlertId))
                {
                    alert.AlertId = Guid.NewGuid().ToString();
                }

                // Store the alert in Cosmos DB
                var response = await _eventsContainer.CreateItemAsync(alert, new PartitionKey(alert.Type.ToString()));
                
                _logger.LogInformation("Alert created with ID: {AlertId}", alert.AlertId);
                return alert.AlertId;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating alert for device {DeviceId}", alert.DeviceId);
                throw;
            }
        }

        public async Task<bool> AcknowledgeAlertAsync(string alertId, string acknowledgedBy)
        {
            try
            {
                _logger.LogInformation("Acknowledging alert {AlertId} by {User}", alertId, acknowledgedBy);

                // Define a query to find the alert by ID
                string query = "SELECT * FROM c WHERE c.alertId = @alertId";
                var queryDef = new QueryDefinition(query)
                    .WithParameter("@alertId", alertId);

                var iterator = _eventsContainer.GetItemQueryIterator<Alert>(queryDef);
                
                while (iterator.HasMoreResults)
                {
                    var response = await iterator.ReadNextAsync();
                    
                    if (response.Count > 0)
                    {
                        var alert = response.First();
                        alert.Acknowledged = true;
                        alert.AcknowledgedTime = DateTime.UtcNow;
                        alert.AcknowledgedBy = acknowledgedBy;

                        // Update the alert in Cosmos DB
                        await _eventsContainer.ReplaceItemAsync(alert, alert.AlertId, new PartitionKey(alert.Type.ToString()));
                        _logger.LogInformation("Alert {AlertId} acknowledged", alertId);
                        return true;
                    }
                }

                _logger.LogWarning("Alert {AlertId} not found for acknowledgment", alertId);
                return false;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error acknowledging alert {AlertId}", alertId);
                return false;
            }
        }

        public async Task<IEnumerable<Alert>> GetActiveAlertsAsync()
        {
            try
            {
                _logger.LogInformation("Getting active alerts");

                // Define a query to find unacknowledged alerts
                string query = "SELECT * FROM c WHERE c.acknowledged = false ORDER BY c.timestamp DESC";
                var queryDef = new QueryDefinition(query);

                var results = new List<Alert>();
                var iterator = _eventsContainer.GetItemQueryIterator<Alert>(queryDef);
                
                while (iterator.HasMoreResults)
                {
                    var response = await iterator.ReadNextAsync();
                    results.AddRange(response);
                }

                _logger.LogInformation("Retrieved {Count} active alerts", results.Count);
                return results;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting active alerts");
                return Enumerable.Empty<Alert>();
            }
        }

        public async Task<IEnumerable<Alert>> GetAlertsByDeviceAsync(string deviceId)
        {
            try
            {
                _logger.LogInformation("Getting alerts for device {DeviceId}", deviceId);

                // Define a query to find alerts for a specific device
                string query = "SELECT * FROM c WHERE c.deviceId = @deviceId ORDER BY c.timestamp DESC";
                var queryDef = new QueryDefinition(query)
                    .WithParameter("@deviceId", deviceId);

                var results = new List<Alert>();
                var iterator = _eventsContainer.GetItemQueryIterator<Alert>(queryDef);
                
                while (iterator.HasMoreResults)
                {
                    var response = await iterator.ReadNextAsync();
                    results.AddRange(response);
                }

                _logger.LogInformation("Retrieved {Count} alerts for device {DeviceId}", results.Count, deviceId);
                return results;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting alerts for device {DeviceId}", deviceId);
                return Enumerable.Empty<Alert>();
            }
        }

        public async Task<IEnumerable<Alert>> GetAlertsByTypeAsync(AlertType type)
        {
            try
            {
                _logger.LogInformation("Getting alerts of type {AlertType}", type);

                // Define a query to find alerts of a specific type
                string query = "SELECT * FROM c WHERE c.type = @type ORDER BY c.timestamp DESC";
                var queryDef = new QueryDefinition(query)
                    .WithParameter("@type", type.ToString());

                var results = new List<Alert>();
                var iterator = _eventsContainer.GetItemQueryIterator<Alert>(queryDef, requestOptions: new QueryRequestOptions { PartitionKey = new PartitionKey(type.ToString()) });
                
                while (iterator.HasMoreResults)
                {
                    var response = await iterator.ReadNextAsync();
                    results.AddRange(response);
                }

                _logger.LogInformation("Retrieved {Count} alerts of type {AlertType}", results.Count, type);
                return results;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting alerts of type {AlertType}", type);
                return Enumerable.Empty<Alert>();
            }
        }

        public async Task<IEnumerable<Alert>> GetAlertsByDateRangeAsync(DateTime startTime, DateTime endTime)
        {
            try
            {
                _logger.LogInformation("Getting alerts between {StartTime} and {EndTime}", startTime, endTime);

                // Define a query to find alerts within a date range
                string query = "SELECT * FROM c WHERE c.timestamp >= @startTime AND c.timestamp <= @endTime ORDER BY c.timestamp DESC";
                var queryDef = new QueryDefinition(query)
                    .WithParameter("@startTime", startTime.ToString("o"))
                    .WithParameter("@endTime", endTime.ToString("o"));

                var results = new List<Alert>();
                var iterator = _eventsContainer.GetItemQueryIterator<Alert>(queryDef);
                
                while (iterator.HasMoreResults)
                {
                    var response = await iterator.ReadNextAsync();
                    results.AddRange(response);
                }

                _logger.LogInformation("Retrieved {Count} alerts between {StartTime} and {EndTime}", results.Count, startTime, endTime);
                return results;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting alerts by date range");
                return Enumerable.Empty<Alert>();
            }
        }
    }
}
"@
Set-Content -Path $alertManagerServicePath -Value $alertManagerServiceContent
Write-Host "  Created: AlertManagerService.cs"

Write-Host "Processing projects created successfully" -ForegroundColor Green
#endregion

#region Create Integration Projects
Write-Host "Creating Integration projects..." -ForegroundColor Cyan

$projectPath = Join-Path -Path $outputPath -ChildPath "src\WAT.IoT.Integration"
$projectFile = Join-Path -Path $projectPath -ChildPath "WAT.IoT.Integration.csproj"

# Create Integration project if it doesn't exist
if (-not (Test-Path $projectFile)) {
    Set-Location $projectPath
    & dotnet new classlib
    
    # Update Integration project file with required packages
    $projectContent = @"
<Project Sdk="Microsoft.NET.Sdk">

  <PropertyGroup>
    <TargetFramework>net6.0</TargetFramework>
    <ImplicitUsings>enable</ImplicitUsings>
    <Nullable>enable</Nullable>
  </PropertyGroup>

  <ItemGroup>
    <PackageReference Include="Microsoft.Extensions.Http" Version="6.0.0" />
    <PackageReference Include="Microsoft.Extensions.Logging.Abstractions" Version="6.0.0" />
    <PackageReference Include="Microsoft.Extensions.Options" Version="6.0.0" />
    <PackageReference Include="Newtonsoft.Json" Version="13.0.3" />
  </ItemGroup>

  <ItemGroup>
    <ProjectReference Include="..\WAT.IoT.Core\WAT.IoT.Core.csproj" />
  </ItemGroup>

</Project>
"@
    
    Set-Content -Path $projectFile -Value $projectContent
    Write-Host "  Created project: WAT.IoT.Integration"
    
    # Add project to solution
    Set-Location $outputPath
    & dotnet sln add "src\WAT.IoT.Integration\WAT.IoT.Integration.csproj"
}

# Create Configuration folder
$configPath = Join-Path -Path $projectPath -ChildPath "Configuration"

# Create ScadaIntegrationOptions.cs
$scadaOptionsPath = Join-Path -Path $configPath -ChildPath "ScadaIntegrationOptions.cs"
$scadaOptionsContent = @"
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
"@
Set-Content -Path $scadaOptionsPath -Value $scadaOptionsContent
Write-Host "  Created: ScadaIntegrationOptions.cs"

# Create Services folder
$servicesPath = Join-Path -Path $projectPath -ChildPath "Services"

# Create ScadaIntegrationService.cs
$scadaServicePath = Join-Path -Path $servicesPath -ChildPath "ScadaIntegrationService.cs"
$scadaServiceContent = @"
// WAT.IoT.Integration/Services/ScadaIntegrationService.cs
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Newtonsoft.Json;
using System.Net.Http.Headers;
using System.Text;
using WAT.IoT.Core.Interfaces;
using WAT.IoT.Core.Models;
using WAT.IoT.Integration.Configuration;

namespace WAT.IoT.Integration.Services
{
    public class ScadaIntegrationService : IScadaIntegration
    {
        private readonly ILogger<ScadaIntegrationService> _logger;
        private readonly ScadaIntegrationOptions _options;
        private readonly HttpClient _httpClient;
        private readonly Dictionary<string, Queue<ValveCommand>> _mockCommandQueue = new Dictionary<string, Queue<ValveCommand>>();

        public ScadaIntegrationService(
            IOptions<ScadaIntegrationOptions> options,
            ILogger<ScadaIntegrationService> logger,
            IHttpClientFactory httpClientFactory)
        {
            _logger = logger;
            _options = options.Value;
            _httpClient = httpClientFactory.CreateClient("ScadaApi");
            
            // Configure the HTTP client
            _httpClient.BaseAddress = new Uri(_options.ScadaApiBaseUrl);
            _httpClient.Timeout = TimeSpan.FromSeconds(_options.TimeoutSeconds);
            _httpClient.DefaultRequestHeaders.Accept.Clear();
            _httpClient.DefaultRequestHeaders.Accept.Add(new MediaTypeWithQualityHeaderValue("application/json"));
            
            if (!string.IsNullOrEmpty(_options.ApiKey))
            {
                _httpClient.DefaultRequestHeaders.Add("X-API-Key", _options.ApiKey);
            }
        }

        public async Task SendTelemetryToScadaAsync(TelemetryReading telemetry)
        {
            try
            {
                if (_options.EnableMock)
                {
                    _logger.LogInformation("MOCK: Sending telemetry to SCADA for device {DeviceId}", telemetry.DeviceId);
                    return;
                }

                _logger.LogInformation("Sending telemetry to SCADA for device {DeviceId}", telemetry.DeviceId);
                
                var content = new StringContent(
                    JsonConvert.SerializeObject(telemetry), 
                    Encoding.UTF8, 
                    "application/json");
                
                var response = await ExecuteWithRetryAsync(() => 
                    _httpClient.PostAsync(_options.TelemetryEndpoint, content));
                
                if (response.IsSuccessStatusCode)
                {
                    _logger.LogInformation("Successfully sent telemetry to SCADA for device {DeviceId}", telemetry.DeviceId);
                }
                else
                {
                    _logger.LogWarning("Failed to send telemetry to SCADA. Status: {StatusCode}", response.StatusCode);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error sending telemetry to SCADA for device {DeviceId}", telemetry.DeviceId);
            }
        }

        public async Task SendAlertToScadaAsync(Alert alert)
        {
            try
            {
                if (_options.EnableMock)
                {
                    _logger.LogInformation("MOCK: Sending alert to SCADA: {AlertType} for device {DeviceId}", 
                        alert.Type, alert.DeviceId);
                    return;
                }

                _logger.LogInformation("Sending alert to SCADA: {AlertType} for device {DeviceId}", 
                    alert.Type, alert.DeviceId);
                
                var content = new StringContent(
                    JsonConvert.SerializeObject(alert), 
                    Encoding.UTF8, 
                    "application/json");
                
                var response = await ExecuteWithRetryAsync(() => 
                    _httpClient.PostAsync(_options.AlertEndpoint, content));
                
                if (response.IsSuccessStatusCode)
                {
                    _logger.LogInformation("Successfully sent alert to SCADA: {AlertType} for device {DeviceId}", 
                        alert.Type, alert.DeviceId);
                }
                else
                {
                    _logger.LogWarning("Failed to send alert to SCADA. Status: {StatusCode}", response.StatusCode);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error sending alert to SCADA: {AlertType} for device {DeviceId}", 
                    alert.Type, alert.DeviceId);
            }
        }

        public async Task NotifyValveOperationAsync(string deviceId, ValveAction action)
        {
            try
            {
                if (_options.EnableMock)
                {
                    _logger.LogInformation("MOCK: Notifying SCADA of valve operation: {Action} for device {DeviceId}", 
                        action, deviceId);
                    return;
                }

                _logger.LogInformation("Notifying SCADA of valve operation: {Action} for device {DeviceId}", 
                    action, deviceId);
                
                var payload = new
                {
                    DeviceId = deviceId,
                    Action = action.ToString(),
                    Timestamp = DateTime.UtcNow
                };
                
                var content = new StringContent(
                    JsonConvert.SerializeObject(payload), 
                    Encoding.UTF8, 
                    "application/json");
                
                var response = await ExecuteWithRetryAsync(() => 
                    _httpClient.PostAsync(_options.ValveOperationEndpoint, content));
                
                if (response.IsSuccessStatusCode)
                {
                    _logger.LogInformation("Successfully notified SCADA of valve operation: {Action} for device {DeviceId}", 
                        action, deviceId);
                }
                else
                {
                    _logger.LogWarning("Failed to notify SCADA of valve operation. Status: {StatusCode}", response.StatusCode);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error notifying SCADA of valve operation: {Action} for device {DeviceId}", 
                    action, deviceId);
            }
        }

        public async Task NotifyFloodEventAsync(FloodEvent floodEvent)
        {
            try
            {
                if (_options.EnableMock)
                {
                    _logger.LogInformation("MOCK: Notifying SCADA of flood event: {EventId} at {Location}", 
                        floodEvent.EventId, floodEvent.Location);
                    return;
                }

                _logger.LogInformation("Notifying SCADA of flood event: {EventId} at {Location}", 
                    floodEvent.EventId, floodEvent.Location);
                
                var content = new StringContent(
                    JsonConvert.SerializeObject(floodEvent), 
                    Encoding.UTF8, 
                    "application/json");
                
                var response = await ExecuteWithRetryAsync(() => 
                    _httpClient.PostAsync(_options.FloodEventEndpoint, content));
                
                if (response.IsSuccessStatusCode)
                {
                    _logger.LogInformation("Successfully notified SCADA of flood event: {EventId}", floodEvent.EventId);
                }
                else
                {
                    _logger.LogWarning("Failed to notify SCADA of flood event. Status: {StatusCode}", response.StatusCode);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error notifying SCADA of flood event: {EventId}", floodEvent.EventId);
            }
        }

        public async Task<bool> ReceiveCommandFromScadaAsync(ValveCommand command)
        {
            try
            {
                _logger.LogInformation("Received command from SCADA: {Action} for device {DeviceId}", 
                    command.Action, command.DeviceId);
                
                // In a mock scenario, store the command in the queue for later retrieval
                if (_options.EnableMock)
                {
                    if (!_mockCommandQueue.TryGetValue(command.DeviceId, out var queue))
                    {
                        queue = new Queue<ValveCommand>();
                        _mockCommandQueue[command.DeviceId] = queue;
                    }
                    
                    queue.Enqueue(command);
                    return true;
                }
                
                // In a real implementation, this would validate the command
                // and potentially update a database or trigger an event
                
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error receiving command from SCADA: {Action} for device {DeviceId}", 
                    command.Action, command.DeviceId);
                return false;
            }
        }

        // For mock implementation - allows retrieving pending commands
        public ValveCommand? GetNextPendingCommand(string deviceId)
        {
            if (!_options.EnableMock || !_mockCommandQueue.TryGetValue(deviceId, out var queue) || queue.Count == 0)
            {
                return null;
            }
            
            return queue.Dequeue();
        }

        private async Task<HttpResponseMessage> ExecuteWithRetryAsync(Func<Task<HttpResponseMessage>> action)
        {
            int retryCount = 0;
            HttpResponseMessage? response = null;
            
            while (retryCount < _options.RetryCount)
            {
                try
                {
                    response = await action();
                    
                    if (response.IsSuccessStatusCode)
                    {
                        return response;
                    }
                    
                    retryCount++;
                    
                    if (retryCount < _options.RetryCount)
                    {
                        int delay = (int)Math.Pow(2, retryCount) * 1000; // Exponential backoff
                        _logger.LogWarning("Retrying request in {DelayMs}ms. Attempt {Attempt}/{MaxAttempts}", 
                            delay, retryCount + 1, _options.RetryCount);
                        await Task.Delay(delay);
                    }
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Error executing HTTP request. Attempt {Attempt}/{MaxAttempts}", 
                        retryCount + 1, _options.RetryCount);
                    
                    retryCount++;
                    
                    if (retryCount < _options.RetryCount)
                    {
                        int delay = (int)Math.Pow(2, retryCount) * 1000; // Exponential backoff
                        await Task.Delay(delay);
                    }
                    else
                    {
                        throw; // Rethrow if we've exhausted retries
                    }
                }
            }
            
            return response ?? new HttpResponseMessage(System.Net.HttpStatusCode.InternalServerError);
        }
    }
}
"@
Set-Content -Path $scadaServicePath -Value $scadaServiceContent
Write-Host "  Created: ScadaIntegrationService.cs"

# Create FloodManagementService.cs
$floodManagementServicePath = Join-Path -Path $servicesPath -ChildPath "FloodManagementService.cs"
$floodManagementServiceContent = @"
// WAT.IoT.Integration/Services/FloodManagementService.cs
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using WAT.IoT.Core.Interfaces;
using WAT.IoT.Core.Models;
using WAT.IoT.Integration.Configuration;

namespace WAT.IoT.Integration.Services
{
    public class FloodManagementService : IFloodManagement
    {
        private readonly ILogger<FloodManagementService> _logger;
        private readonly ScadaIntegrationOptions _options;
        private readonly IScadaIntegration _scadaIntegration;
        private readonly List<FloodEvent> _activeFloodEvents = new List<FloodEvent>();
        private readonly List<FloodEvent> _historicalFloodEvents = new List<FloodEvent>();
        private readonly SemaphoreSlim _lock = new SemaphoreSlim(1, 1);

        public FloodManagementService(
            IOptions<ScadaIntegrationOptions> options,
            ILogger<FloodManagementService> logger,
            IScadaIntegration scadaIntegration)
        {
            _logger = logger;
            _options = options.Value;
            _scadaIntegration = scadaIntegration;
        }
		public async Task<string> CreateFloodEventAsync(FloodEvent floodEvent)
        {
            try
            {
                await _lock.WaitAsync();
                
                _logger.LogInformation("Creating flood event at location {Location}", floodEvent.Location);
                
                // Set a new ID if not provided
                if (string.IsNullOrEmpty(floodEvent.EventId))
                {
                    floodEvent.EventId = Guid.NewGuid().ToString();
                }
                
                // Ensure start time is set
                if (floodEvent.StartTime == default)
                {
                    floodEvent.StartTime = DateTime.UtcNow;
                }
                
                // Add to active events
                _activeFloodEvents.Add(floodEvent);
                
                // Notify SCADA system
                await _scadaIntegration.NotifyFloodEventAsync(floodEvent);
                
                _logger.LogInformation("Flood event created with ID: {EventId}", floodEvent.EventId);
                return floodEvent.EventId;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating flood event at location {Location}", floodEvent.Location);
                throw;
            }
            finally
            {
                _lock.Release();
            }
        }

        public async Task<bool> UpdateFloodEventAsync(FloodEvent floodEvent)
        {
            try
            {
                await _lock.WaitAsync();
                
                _logger.LogInformation("Updating flood event: {EventId}", floodEvent.EventId);
                
                // Find the event
                var existingEventIndex = _activeFloodEvents.FindIndex(e => e.EventId == floodEvent.EventId);
                
                if (existingEventIndex >= 0)
                {
                    // Update the active event
                    _activeFloodEvents[existingEventIndex] = floodEvent;
                    
                    // Notify SCADA system
                    await _scadaIntegration.NotifyFloodEventAsync(floodEvent);
                    
                    _logger.LogInformation("Flood event updated: {EventId}", floodEvent.EventId);
                    return true;
                }
                else
                {
                    // Check historical events
                    var historicalEventIndex = _historicalFloodEvents.FindIndex(e => e.EventId == floodEvent.EventId);
                    
                    if (historicalEventIndex >= 0)
                    {
                        // Update the historical event
                        _historicalFloodEvents[historicalEventIndex] = floodEvent;
                        
                        // Notify SCADA system
                        await _scadaIntegration.NotifyFloodEventAsync(floodEvent);
                        
                        _logger.LogInformation("Historical flood event updated: {EventId}", floodEvent.EventId);
                        return true;
                    }
                }
                
                _logger.LogWarning("Flood event not found for update: {EventId}", floodEvent.EventId);
                return false;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating flood event: {EventId}", floodEvent.EventId);
                return false;
            }
            finally
            {
                _lock.Release();
            }
        }

        public async Task<bool> CloseFloodEventAsync(string eventId, DateTime endTime)
        {
            try
            {
                await _lock.WaitAsync();
                
                _logger.LogInformation("Closing flood event: {EventId}", eventId);
                
                // Find the event
                var existingEvent = _activeFloodEvents.FirstOrDefault(e => e.EventId == eventId);
                
                if (existingEvent != null)
                {
                    // Update end time
                    existingEvent.EndTime = endTime;
                    
                    // Move to historical events
                    _activeFloodEvents.Remove(existingEvent);
                    _historicalFloodEvents.Add(existingEvent);
                    
                    // Notify SCADA system
                    await _scadaIntegration.NotifyFloodEventAsync(existingEvent);
                    
                    _logger.LogInformation("Flood event closed: {EventId}", eventId);
                    return true;
                }
                
                _logger.LogWarning("Flood event not found for closing: {EventId}", eventId);
                return false;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error closing flood event: {EventId}", eventId);
                return false;
            }
            finally
            {
                _lock.Release();
            }
        }

        public async Task<bool> SubmitRegulationReportAsync(string eventId, string submittedBy)
        {
            try
            {
                await _lock.WaitAsync();
                
                _logger.LogInformation("Submitting regulation report for flood event: {EventId}", eventId);
                
                // Find the event (check both active and historical)
                var floodEvent = _activeFloodEvents.FirstOrDefault(e => e.EventId == eventId) ??
                                _historicalFloodEvents.FirstOrDefault(e => e.EventId == eventId);
                
                if (floodEvent != null)
                {
                    // Update report information
                    floodEvent.HasRegulationReport = true;
                    floodEvent.RegulationReportTime = DateTime.UtcNow;
                    floodEvent.ReportSubmittedBy = submittedBy;
                    
                    // Notify SCADA system
                    await _scadaIntegration.NotifyFloodEventAsync(floodEvent);
                    
                    _logger.LogInformation("Regulation report submitted for flood event: {EventId}", eventId);
                    return true;
                }
                
                _logger.LogWarning("Flood event not found for regulation report: {EventId}", eventId);
                return false;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error submitting regulation report for flood event: {EventId}", eventId);
                return false;
            }
            finally
            {
                _lock.Release();
            }
        }

        public async Task<IEnumerable<FloodEvent>> GetActiveFloodEventsAsync()
        {
            try
            {
                await _lock.WaitAsync();
                return _activeFloodEvents.ToList();
            }
            finally
            {
                _lock.Release();
            }
        }

        public async Task<IEnumerable<FloodEvent>> GetFloodEventsByDateRangeAsync(DateTime startTime, DateTime endTime)
        {
            try
            {
                await _lock.WaitAsync();
                
                var result = new List<FloodEvent>();
                
                // Check active events
                result.AddRange(_activeFloodEvents.Where(e => e.StartTime >= startTime && 
                    (e.EndTime == null || e.EndTime <= endTime)));
                
                // Check historical events
                result.AddRange(_historicalFloodEvents.Where(e => e.StartTime >= startTime && 
                    (e.EndTime == null || e.EndTime <= endTime)));
                
                return result;
            }
            finally
            {
                _lock.Release();
            }
        }

        public async Task<FloodEvent?> GetFloodEventByIdAsync(string eventId)
        {
            try
            {
                await _lock.WaitAsync();
                
                // Check active events first
                var activeEvent = _activeFloodEvents.FirstOrDefault(e => e.EventId == eventId);
                
                if (activeEvent != null)
                {
                    return activeEvent;
                }
                
                // Check historical events
                return _historicalFloodEvents.FirstOrDefault(e => e.EventId == eventId);
            }
            finally
            {
                _lock.Release();
            }
        }
    }
}
"@
Set-Content -Path $floodManagementServicePath -Value $floodManagementServiceContent
Write-Host "  Created: FloodManagementService.cs"

Write-Host "Integration projects created successfully" -ForegroundColor Green
#endregion

#region Create API Projects
Write-Host "Creating API projects..." -ForegroundColor Cyan

$projectPath = Join-Path -Path $outputPath -ChildPath "src\WAT.IoT.Api"
$projectFile = Join-Path -Path $projectPath -ChildPath "WAT.IoT.Api.csproj"

# Create API project if it doesn't exist
if (-not (Test-Path $projectFile)) {
    Set-Location $projectPath
    & dotnet new webapi --no-https --no-openapi
    
    # Update API project file with required packages
    $projectContent = @"
<Project Sdk="Microsoft.NET.Sdk.Web">

  <PropertyGroup>
    <TargetFramework>net6.0</TargetFramework>
    <Nullable>enable</Nullable>
    <ImplicitUsings>enable</ImplicitUsings>
  </PropertyGroup>

  <ItemGroup>
    <PackageReference Include="Microsoft.ApplicationInsights.AspNetCore" Version="2.21.0" />
    <PackageReference Include="Microsoft.AspNetCore.Authentication.JwtBearer" Version="6.0.21" />
    <PackageReference Include="Swashbuckle.AspNetCore" Version="6.5.0" />
  </ItemGroup>

  <ItemGroup>
    <ProjectReference Include="..\WAT.IoT.Core\WAT.IoT.Core.csproj" />
    <ProjectReference Include="..\WAT.IoT.Devices\WAT.IoT.Devices.csproj" />
    <ProjectReference Include="..\WAT.IoT.Processing\WAT.IoT.Processing.csproj" />
    <ProjectReference Include="..\WAT.IoT.Integration\WAT.IoT.Integration.csproj" />
  </ItemGroup>

</Project>
"@
    
    Set-Content -Path $projectFile -Value $projectContent
    Write-Host "  Created project: WAT.IoT.Api"
    
    # Add project to solution
    Set-Location $outputPath
    & dotnet sln add "src\WAT.IoT.Api\WAT.IoT.Api.csproj"
}

# Create Controllers folder
$controllersPath = Join-Path -Path $projectPath -ChildPath "Controllers"

# Create DevicesController.cs
$devicesControllerPath = Join-Path -Path $controllersPath -ChildPath "DevicesController.cs"
$devicesControllerContent = @"
// WAT.IoT.Api/Controllers/DevicesController.cs
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using WAT.IoT.Core.Interfaces;
using WAT.IoT.Core.Models;

namespace WAT.IoT.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class DevicesController : ControllerBase
    {
        private readonly IDeviceRegistry _deviceRegistry;
        private readonly IDeviceCommunication _deviceCommunication;
        private readonly ILogger<DevicesController> _logger;

        public DevicesController(
            IDeviceRegistry deviceRegistry,
            IDeviceCommunication deviceCommunication,
            ILogger<DevicesController> logger)
        {
            _deviceRegistry = deviceRegistry;
            _deviceCommunication = deviceCommunication;
            _logger = logger;
        }

        [HttpGet]
        public async Task<ActionResult<IEnumerable<DeviceInfo>>> GetAllDevices()
        {
            try
            {
                var devices = await _deviceRegistry.GetAllDevicesAsync();
                return Ok(devices);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting all devices");
                return StatusCode(500, "An error occurred while retrieving devices");
            }
        }

        [HttpGet("{deviceId}")]
        public async Task<ActionResult<DeviceInfo>> GetDevice(string deviceId)
        {
            try
            {
                var device = await _deviceRegistry.GetDeviceInfoAsync(deviceId);
                
                if (device == null || string.IsNullOrEmpty(device.DeviceId))
                {
                    return NotFound($"Device with ID {deviceId} not found");
                }
                
                return Ok(device);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting device {DeviceId}", deviceId);
                return StatusCode(500, $"An error occurred while retrieving device {deviceId}");
            }
        }

        [HttpGet("{deviceId}/telemetry")]
        public async Task<ActionResult<TelemetryReading>> GetDeviceTelemetry(string deviceId)
        {
            try
            {
                var telemetry = await _deviceCommunication.GetLatestTelemetryAsync(deviceId);
                
                if (telemetry == null)
                {
                    return NotFound($"No telemetry found for device {deviceId}");
                }
                
                return Ok(telemetry);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting telemetry for device {DeviceId}", deviceId);
                return StatusCode(500, $"An error occurred while retrieving telemetry for device {deviceId}");
            }
        }

        [HttpGet("location/{location}")]
        public async Task<ActionResult<IEnumerable<DeviceInfo>>> GetDevicesByLocation(string location)
        {
            try
            {
                var devices = await _deviceRegistry.GetDevicesByLocationAsync(location);
                return Ok(devices);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting devices by location {Location}", location);
                return StatusCode(500, $"An error occurred while retrieving devices for location {location}");
            }
        }

        [HttpPost]
        public async Task<ActionResult<DeviceInfo>> AddDevice(DeviceInfo device)
        {
            try
            {
                var isRegistered = await _deviceRegistry.IsDeviceRegisteredAsync(device.DeviceId);
                
                if (isRegistered)
                {
                    return Conflict($"Device with ID {device.DeviceId} already exists");
                }
                
                var result = await _deviceRegistry.AddDeviceAsync(device);
                
                if (!result)
                {
                    return BadRequest("Failed to add device");
                }
                
                return CreatedAtAction(nameof(GetDevice), new { deviceId = device.DeviceId }, device);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error adding device {DeviceId}", device.DeviceId);
                return StatusCode(500, $"An error occurred while adding device {device.DeviceId}");
            }
        }

        [HttpPut("{deviceId}")]
        public async Task<IActionResult> UpdateDevice(string deviceId, DeviceInfo device)
        {
            try
            {
                if (deviceId != device.DeviceId)
                {
                    return BadRequest("Device ID in the URL does not match the device ID in the request body");
                }
                
                var isRegistered = await _deviceRegistry.IsDeviceRegisteredAsync(deviceId);
                
                if (!isRegistered)
                {
                    return NotFound($"Device with ID {deviceId} not found");
                }
                
                var result = await _deviceRegistry.UpdateDeviceAsync(device);
                
                if (!result)
                {
                    return BadRequest("Failed to update device");
                }
                
                return NoContent();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating device {DeviceId}", deviceId);
                return StatusCode(500, $"An error occurred while updating device {deviceId}");
            }
        }

        [HttpDelete("{deviceId}")]
        public async Task<IActionResult> DeleteDevice(string deviceId)
        {
            try
            {
                var isRegistered = await _deviceRegistry.IsDeviceRegisteredAsync(deviceId);
                
                if (!isRegistered)
                {
                    return NotFound($"Device with ID {deviceId} not found");
                }
                
                var result = await _deviceRegistry.DeleteDeviceAsync(deviceId);
                
                if (!result)
                {
                    return BadRequest("Failed to delete device");
                }
                
                return NoContent();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting device {DeviceId}", deviceId);
                return StatusCode(500, $"An error occurred while deleting device {deviceId}");
            }
        }

        [HttpPost("{deviceId}/command")]
        public async Task<IActionResult> SendCommand(string deviceId, [FromBody] ValveCommand command)
        {
            try
            {
                if (deviceId != command.DeviceId)
                {
                    return BadRequest("Device ID in the URL does not match the device ID in the command");
                }
                
                var isRegistered = await _deviceRegistry.IsDeviceRegisteredAsync(deviceId);
                
                if (!isRegistered)
                {
                    return NotFound($"Device with ID {deviceId} not found");
                }
                
                var result = await _deviceCommunication.SendCommandAsync(deviceId, command);
                
                if (!result)
                {
                    return BadRequest("Failed to send command to device");
                }
                
                return Ok();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error sending command to device {DeviceId}", deviceId);
                return StatusCode(500, $"An error occurred while sending command to device {deviceId}");
            }
        }
    }
}
"@
Set-Content -Path $devicesControllerPath -Value $devicesControllerContent
Write-Host "  Created: DevicesController.cs"

# Create AlertsController.cs
$alertsControllerPath = Join-Path -Path $controllersPath -ChildPath "AlertsController.cs"
$alertsControllerContent = @"
// WAT.IoT.Api/Controllers/AlertsController.cs
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using WAT.IoT.Core.Interfaces;
using WAT.IoT.Core.Models;

namespace WAT.IoT.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class AlertsController : ControllerBase
    {
        private readonly IAlertManager _alertManager;
        private readonly ILogger<AlertsController> _logger;

        public AlertsController(
            IAlertManager alertManager,
            ILogger<AlertsController> logger)
        {
            _alertManager = alertManager;
            _logger = logger;
        }

        [HttpGet("active")]
        public async Task<ActionResult<IEnumerable<Alert>>> GetActiveAlerts()
        {
            try
            {
                var alerts = await _alertManager.GetActiveAlertsAsync();
                return Ok(alerts);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting active alerts");
                return StatusCode(500, "An error occurred while retrieving active alerts");
            }
        }

        [HttpGet("device/{deviceId}")]
        public async Task<ActionResult<IEnumerable<Alert>>> GetAlertsByDevice(string deviceId)
        {
            try
            {
                var alerts = await _alertManager.GetAlertsByDeviceAsync(deviceId);
                return Ok(alerts);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting alerts for device {DeviceId}", deviceId);
                return StatusCode(500, $"An error occurred while retrieving alerts for device {deviceId}");
            }
        }

        [HttpGet("type/{alertType}")]
        public async Task<ActionResult<IEnumerable<Alert>>> GetAlertsByType(AlertType alertType)
        {
            try
            {
                var alerts = await _alertManager.GetAlertsByTypeAsync(alertType);
                return Ok(alerts);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting alerts of type {AlertType}", alertType);
                return StatusCode(500, $"An error occurred while retrieving alerts of type {alertType}");
            }
        }

        [HttpGet("daterange")]
        public async Task<ActionResult<IEnumerable<Alert>>> GetAlertsByDateRange(
            [FromQuery] DateTime startTime, 
            [FromQuery] DateTime endTime)
        {
            try
            {
                if (startTime >= endTime)
                {
                    return BadRequest("Start time must be earlier than end time");
                }
                
                var alerts = await _alertManager.GetAlertsByDateRangeAsync(startTime, endTime);
                return Ok(alerts);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting alerts by date range");
                return StatusCode(500, "An error occurred while retrieving alerts by date range");
            }
        }

        [HttpPost("{alertId}/acknowledge")]
        public async Task<IActionResult> AcknowledgeAlert(string alertId, [FromBody] AcknowledgeRequest request)
        {
            try
            {
                var result = await _alertManager.AcknowledgeAlertAsync(alertId, request.AcknowledgedBy);
                
                if (!result)
                {
                    return NotFound($"Alert with ID {alertId} not found");
                }
                
                return Ok();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error acknowledging alert {AlertId}", alertId);
                return StatusCode(500, $"An error occurred while acknowledging alert {alertId}");
            }
        }

        public class AcknowledgeRequest
        {
            public string AcknowledgedBy { get; set; } = string.Empty;
        }
    }
}
"@
Set-Content -Path $alertsControllerPath -Value $alertsControllerContent
Write-Host "  Created: AlertsController.cs"

# Create FloodEventsController.cs
$floodEventsControllerPath = Join-Path -Path $controllersPath -ChildPath "FloodEventsController.cs"
$floodEventsControllerContent = @"
// WAT.IoT.Api/Controllers/FloodEventsController.cs
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using WAT.IoT.Core.Interfaces;
using WAT.IoT.Core.Models;

namespace WAT.IoT.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class FloodEventsController : ControllerBase
    {
        private readonly IFloodManagement _floodManagement;
        private readonly ILogger<FloodEventsController> _logger;

        public FloodEventsController(
            IFloodManagement floodManagement,
            ILogger<FloodEventsController> logger)
        {
            _floodManagement = floodManagement;
            _logger = logger;
        }

        [HttpGet("active")]
        public async Task<ActionResult<IEnumerable<FloodEvent>>> GetActiveFloodEvents()
        {
            try
            {
                var events = await _floodManagement.GetActiveFloodEventsAsync();
                return Ok(events);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting active flood events");
                return StatusCode(500, "An error occurred while retrieving active flood events");
            }
        }

        [HttpGet("{eventId}")]
        public async Task<ActionResult<FloodEvent>> GetFloodEvent(string eventId)
        {
            try
            {
                var floodEvent = await _floodManagement.GetFloodEventByIdAsync(eventId);
                
                if (floodEvent == null)
                {
                    return NotFound($"Flood event with ID {eventId} not found");
                }
                
                return Ok(floodEvent);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting flood event {EventId}", eventId);
                return StatusCode(500, $"An error occurred while retrieving flood event {eventId}");
            }
        }

        [HttpGet("daterange")]
        public async Task<ActionResult<IEnumerable<FloodEvent>>> GetFloodEventsByDateRange(
            [FromQuery] DateTime startTime, 
            [FromQuery] DateTime endTime)
        {
            try
            {
                if (startTime >= endTime)
                {
                    return BadRequest("Start time must be earlier than end time");
                }
                
                var events = await _floodManagement.GetFloodEventsByDateRangeAsync(startTime, endTime);
                return Ok(events);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting flood events by date range");
                return StatusCode(500, "An error occurred while retrieving flood events by date range");
            }
        }

        [HttpPost]
        public async Task<ActionResult<string>> CreateFloodEvent(FloodEvent floodEvent)
        {
            try
            {
                var eventId = await _floodManagement.CreateFloodEventAsync(floodEvent);
                return CreatedAtAction(nameof(GetFloodEvent), new { eventId }, eventId);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating flood event");
                return StatusCode(500, "An error occurred while creating flood event");
            }
        }

        [HttpPut("{eventId}")]
        public async Task<IActionResult> UpdateFloodEvent(string eventId, FloodEvent floodEvent)
        {
            try
            {
                if (eventId != floodEvent.EventId)
                {
                    return BadRequest("Event ID in the URL does not match the event ID in the request body");
                }
                
                var result = await _floodManagement.UpdateFloodEventAsync(floodEvent);
                
                if (!result)
                {
                    return NotFound($"Flood event with ID {eventId} not found");
                }
                
                return NoContent();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating flood event {EventId}", eventId);
                return StatusCode(500, $"An error occurred while updating flood event {eventId}");
            }
        }

        [HttpPost("{eventId}/close")]
        public async Task<IActionResult> CloseFloodEvent(string eventId, [FromBody] CloseEventRequest request)
        {
            try
            {
                var result = await _floodManagement.CloseFloodEventAsync(eventId, request.EndTime);
                
                if (!result)
                {
                    return NotFound($"Flood event with ID {eventId} not found");
                }
                
                return Ok();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error closing flood event {EventId}", eventId);
                return StatusCode(500, $"An error occurred while closing flood event {eventId}");
            }
        }

        [HttpPost("{eventId}/report")]
        public async Task<IActionResult> SubmitRegulationReport(string eventId, [FromBody] ReportRequest request)
        {
            try
            {
                var result = await _floodManagement.SubmitRegulationReportAsync(eventId, request.SubmittedBy);
                
                if (!result)
                {
                    return NotFound($"Flood event with ID {eventId} not found");
                }
                
                return Ok();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error submitting regulation report for flood event {EventId}", eventId);
                return StatusCode(500, $"An error occurred while submitting regulation report for flood event {eventId}");
            }
        }

        public class CloseEventRequest
        {
            public DateTime EndTime { get; set; } = DateTime.UtcNow;
        }

        public class ReportRequest
        {
            public string SubmittedBy { get; set; } = string.Empty;
        }
    }
}
"@
Set-Content -Path $floodEventsControllerPath -Value $floodEventsControllerContent
Write-Host "  Created: FloodEventsController.cs"

# Create HealthController.cs
$healthControllerPath = Join-Path -Path $controllersPath -ChildPath "HealthController.cs"
$healthControllerContent = @"
// WAT.IoT.Api/Controllers/HealthController.cs
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace WAT.IoT.Api.Controllers
{
    [ApiController]
    [Route("health")]
    [AllowAnonymous]
    public class HealthController : ControllerBase
    {
        private readonly ILogger<HealthController> _logger;

        public HealthController(ILogger<HealthController> logger)
        {
            _logger = logger;
        }

        [HttpGet]
        public IActionResult Get()
        {
            try
            {
                return Ok(new { Status = "Healthy", Timestamp = DateTime.UtcNow });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Health check failed");
                return StatusCode(500, new { Status = "Unhealthy", Error = ex.Message });
            }
        }
    }
}
"@
Set-Content -Path $healthControllerPath -Value $healthControllerContent
Write-Host "  Created: HealthController.cs"

# Create Program.cs
$programPath = Join-Path -Path $projectPath -ChildPath "Program.cs"
$programContent = @"
// WAT.IoT.Api/Program.cs
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using System.Text;
using WAT.IoT.Core.Interfaces;
using WAT.IoT.Devices.Configuration;
using WAT.IoT.Devices.Services;
using WAT.IoT.Integration.Configuration;
using WAT.IoT.Integration.Services;
using WAT.IoT.Processing.Configuration;
using WAT.IoT.Processing.Services;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddApplicationInsightsTelemetry();
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// Configure options
builder.Services.Configure<IoTHubOptions>(builder.Configuration.GetSection("IoTHub"));
builder.Services.Configure<ProcessingOptions>(builder.Configuration.GetSection("Processing"));
builder.Services.Configure<ScadaIntegrationOptions>(builder.Configuration.GetSection("ScadaIntegration"));

// Register HTTP clients
builder.Services.AddHttpClient();

// Register core services
builder.Services.AddSingleton<IDeviceRegistry, DeviceRegistryService>();
builder.Services.AddSingleton<IDeviceCommunication, DeviceCommunicationService>();
builder.Services.AddSingleton<ITelemetryProcessor, TelemetryProcessorService>();
builder.Services.AddSingleton<IAlertManager, AlertManagerService>();
builder.Services.AddSingleton<IScadaIntegration, ScadaIntegrationService>();
builder.Services.AddSingleton<IFloodManagement, FloodManagementService>();

// Configure JWT authentication
var jwtSettings = builder.Configuration.GetSection("JwtSettings");
var key = Encoding.ASCII.GetBytes(jwtSettings["Secret"] ?? "DefaultSecretKeyThatShouldBeReplacedInProduction");

builder.Services.AddAuthentication(x =>
{
    x.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    x.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(x =>
{
    x.RequireHttpsMetadata = false;
    x.SaveToken = true;
    x.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuerSigningKey = true,
        IssuerSigningKey = new SymmetricSecurityKey(key),
        ValidateIssuer = true,
        ValidIssuer = jwtSettings["Issuer"],
        ValidateAudience = true,
        ValidAudience = jwtSettings["Audience"],
        ValidateLifetime = true,
        ClockSkew = TimeSpan.Zero
    };
});

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

// Initialize telemetry processor
var telemetryProcessor = app.Services.GetRequiredService<ITelemetryProcessor>();
if (telemetryProcessor is TelemetryProcessorService processorService)
{
    Task.Run(async () =>
    {
        try
        {
            await processorService.StartProcessingAsync();
        }
        catch (Exception ex)
        {
            var logger = app.Services.GetRequiredService<ILogger<Program>>();
            logger.LogError(ex, "Error starting telemetry processor");
        }
    });
}

app.Run();
"@
Set-Content -Path $programPath -Value $programContent
Write-Host "  Created: Program.cs"

# Create appsettings.json
$appsettingsPath = Join-Path -Path $projectPath -ChildPath "appsettings.json"
$appsettingsContent = @"
{
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  },
  "AllowedHosts": "*",
  "ApplicationInsights": {
    "ConnectionString": ""
  },
  "JwtSettings": {
    "Secret": "ThisIsAVeryLongSecretKeyForSigningJwtTokens",
    "Issuer": "WAT.IoT.Api",
    "Audience": "WAT.IoT.Clients",
    "ExpiryMinutes": 60
  },
  "ApiKey": "WaterTreatmentApiKey2023",
  "IoTHub": {
    "ConnectionString": "",
    "DpsIdScope": "",
    "DpsGlobalEndpoint": "global.azure-devices-provisioning.net",
    "DefaultTimeoutSeconds": 30,
    "EnableTwinSync": true,
    "EnableLogging": true,
    "RetryCount": 3,
    "RetryIntervalMilliseconds": 1000
  },
  "Processing": {
    "EventHubConnectionString": "",
    "EventHubName": "telemetry",
    "ConsumerGroup": "$Default",
    "CosmosDbConnectionString": "",
    "CosmosDbDatabaseName": "WATOperationalData",
    "TelemetryContainerName": "telemetry",
    "EventsContainerName": "events",
    "WaterQualityContainerName": "waterQuality",
    "StorageConnectionString": "",
    "StorageContainerName": "checkpoints",
    "TelemetryProcessingBatchSize": 100,
    "MaxConcurrentProcessingTasks": 10,
    "AlertThresholdPeriodMinutes": 10,
    "EnableAnomalyDetection": true,
    "HighWaterLevelThreshold": 80.0,
    "LowWaterLevelThreshold": 20.0,
    "HighPressureThreshold": 100.0,
    "LowPressureThreshold": 10.0,
    "WaterQualityThreshold": 50.0,
    "BatteryLowThreshold": 15.0
  },
  "ScadaIntegration": {
    "ScadaApiBaseUrl": "http://localhost:5000/api/scada",
    "TelemetryEndpoint": "telemetry",
    "AlertEndpoint": "alert",
    "ValveOperationEndpoint": "valve",
    "FloodEventEndpoint": "flood",
    "ApiKey": "",
    "TimeoutSeconds": 30,
    "RetryCount": 3,
    "EnableMock": true
  }
}
"@
Set-Content -Path $appsettingsPath -Value $appsettingsContent
Write-Host "  Created: appsettings.json"

Write-Host "API projects created successfully" -ForegroundColor Green
#endregion

#region Create Functions Projects
Write-Host "Creating Functions projects..." -ForegroundColor Cyan

$projectPath = Join-Path -Path $outputPath -ChildPath "src\WAT.IoT.Functions"
$projectFile = Join-Path -Path $projectPath -ChildPath "WAT.IoT.Functions.csproj"

# Create Functions project if it doesn't exist
if (-not (Test-Path $projectFile)) {
    Set-Location $projectPath
    & dotnet new functionapp --no-http
    
    # Update Functions project file with required packages
    $projectContent = @"
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net6.0</TargetFramework>
    <AzureFunctionsVersion>v4</AzureFunctionsVersion>
    <ImplicitUsings>enable</ImplicitUsings>
    <Nullable>enable</Nullable>
  </PropertyGroup>
  <ItemGroup>
    <PackageReference Include="Microsoft.ApplicationInsights.WorkerService" Version="2.21.0" />
    <PackageReference Include="Microsoft.Azure.Cosmos" Version="3.35.3" />
    <PackageReference Include="Microsoft.Azure.Functions.Extensions" Version="1.1.0" />
    <PackageReference Include="Microsoft.Azure.WebJobs.Extensions.CosmosDB" Version="4.3.0" />
    <PackageReference Include="Microsoft.Azure.WebJobs.Extensions.EventHubs" Version="5.2.0" />
    <PackageReference Include="Microsoft.NET.Sdk.Functions" Version="4.2.0" />
  </ItemGroup>
  <ItemGroup>
    <ProjectReference Include="..\WAT.IoT.Core\WAT.IoT.Core.csproj" />
    <ProjectReference Include="..\WAT.IoT.Devices\WAT.IoT.Devices.csproj" />
    <ProjectReference Include="..\WAT.IoT.Processing\WAT.IoT.Processing.csproj" />
    <ProjectReference Include="..\WAT.IoT.Integration\WAT.IoT.Integration.csproj" />
  </ItemGroup>
  <ItemGroup>
    <None Update="host.json">
      <CopyToOutputDirectory>PreserveNewest</CopyToOutputDirectory>
    </None>
    <None Update="local.settings.json">
      <CopyToOutputDirectory>PreserveNewest</CopyToOutputDirectory>
      <CopyToPublishDirectory>Never</CopyToPublishDirectory>
    </None>
  </ItemGroup>
</Project>
"@
    
    Set-Content -Path $projectFile -Value $projectContent
    Write-Host "  Created project: WAT.IoT.Functions"
    
    # Add project to solution
    Set-Location $outputPath
    & dotnet sln add "src\WAT.IoT.Functions\WAT.IoT.Functions.csproj"
}

# Create host.json
$hostJsonPath = Join-Path -Path $projectPath -ChildPath "host.json"
$hostJsonContent = @"
{
  "version": "2.0",
  "logging": {
    "applicationInsights": {
      "samplingSettings": {
        "isEnabled": true,
        "excludedTypes": "Request"
      }
    },
    "logLevel": {
      "default": "Information",
      "Host.Results": "Error",
      "Function": "Information",
      "Host.Aggregator": "Trace"
    }
  },
  "extensions": {
    "cosmosDB": {
      "connectionMode": "Gateway",
      "protocol": "Https"
    },
    "eventHubs": {
      "batchCheckpointFrequency": 5,
      "eventProcessorOptions": {
        "maxBatchSize": 100,
        "prefetchCount": 300
      }
    }
  }
}
"@
Set-Content -Path $hostJsonPath -Value $hostJsonContent
Write-Host "  Created: host.json"

# Create local.settings.json
$localSettingsPath = Join-Path -Path $projectPath -ChildPath "local.settings.json"
$localSettingsContent = @"
{
  "IsEncrypted": false,
  "Values": {
    "AzureWebJobsStorage": "UseDevelopmentStorage=true",
    "FUNCTIONS_WORKER_RUNTIME": "dotnet",
    "EventHubConnection": "",
    "CosmosDbConnection": "",
    "CosmosDbName": "WATOperationalData",
    "TelemetryContainer": "telemetry",
    "EventsContainer": "events",
    "WaterQualityContainer": "waterQuality",
    "IoTHubConnectionString": "",
    "AlertsApiUrl": "",
    "ApiKey": "",
    "NotificationApiUrl": "",
    "AlertThresholds:HighPressure": "100.0",
    "AlertThresholds:LowPressure": "10.0",
    "AlertThresholds:WaterQuality": "50.0",
    "AlertThresholds:BatteryLow": "15.0",
    "ScadaIntegration:ScadaApiBaseUrl": "http://localhost:5000/api/scada",
    "ScadaIntegration:AlertEndpoint": "alert",
    "ScadaIntegration:ApiKey": ""
  }
}
"@
Set-Content -Path $localSettingsPath -Value $localSettingsContent
Write-Host "  Created: local.settings.json"

# Create Functions folder
$functionsPath = Join-Path -Path $projectPath -ChildPath "Functions"
New-Item -ItemType Directory -Path $functionsPath -Force | Out-Null

# Create Startup.cs
$startupPath = Join-Path -Path $projectPath -ChildPath "Startup.cs"
$startupContent = @"
// WAT.IoT.Functions/Startup.cs
using Microsoft.Azure.Functions.Extensions.DependencyInjection;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using WAT.IoT.Core.Interfaces;
using WAT.IoT.Devices.Configuration;
using WAT.IoT.Devices.Services;
using WAT.IoT.Integration.Configuration;
using WAT.IoT.Integration.Services;
using WAT.IoT.Processing.Configuration;
using WAT.IoT.Processing.Services;

[assembly: FunctionsStartup(typeof(WAT.IoT.Functions.Startup))]

namespace WAT.IoT.Functions
{
    public class Startup : FunctionsStartup
    {
        public override void Configure(IFunctionsHostBuilder builder)
        {
            // Get configuration
            var configuration = builder.GetContext().Configuration;

            // Configure options
            builder.Services.Configure<IoTHubOptions>(options =>
            {
                options.ConnectionString = configuration["IoTHubConnectionString"];
                options.DpsIdScope = configuration["DpsIdScope"];
                options.DpsGlobalEndpoint = configuration["DpsGlobalEndpoint"];
                options.DefaultTimeoutSeconds = int.Parse(configuration["DefaultTimeoutSeconds"] ?? "30");
                options.EnableTwinSync = bool.Parse(configuration["EnableTwinSync"] ?? "true");
                options.EnableLogging = bool.Parse(configuration["EnableLogging"] ?? "true");
                options.RetryCount = int.Parse(configuration["RetryCount"] ?? "3");
                options.RetryIntervalMilliseconds = int.Parse(configuration["RetryIntervalMilliseconds"] ?? "1000");
            });

            builder.Services.Configure<ProcessingOptions>(options =>
            {
                options.EventHubConnectionString = configuration["EventHubConnection"];
                options.EventHubName = configuration["EventHubName"] ?? "telemetry";
                options.ConsumerGroup = configuration["ConsumerGroup"] ?? "$Default";
                options.CosmosDbConnectionString = configuration["CosmosDbConnection"];
                options.CosmosDbDatabaseName = configuration["CosmosDbName"];
                options.TelemetryContainerName = configuration["TelemetryContainer"];
                options.EventsContainerName = configuration["EventsContainer"];
                options.WaterQualityContainerName = configuration["WaterQualityContainer"];
                options.HighPressureThreshold = double.Parse(configuration["AlertThresholds:HighPressure"] ?? "100.0");
                options.LowPressureThreshold = double.Parse(configuration["AlertThresholds:LowPressure"] ?? "10.0");
                options.WaterQualityThreshold = double.Parse(configuration["AlertThresholds:WaterQuality"] ?? "50.0");
                options.BatteryLowThreshold = double.Parse(configuration["AlertThresholds:BatteryLow"] ?? "15.0");
            });

            builder.Services.Configure<ScadaIntegrationOptions>(options =>
            {
                options.ScadaApiBaseUrl = configuration["ScadaIntegration:ScadaApiBaseUrl"];
                options.AlertEndpoint = configuration["ScadaIntegration:AlertEndpoint"];
                options.ApiKey = configuration["ScadaIntegration:ApiKey"];
            });

            // Register HTTP clients
            builder.Services.AddHttpClient();

            // Register services
            builder.Services.AddSingleton<IDeviceRegistry, DeviceRegistryService>();
            builder.Services.AddSingleton<IDeviceCommunication, DeviceCommunicationService>();
            builder.Services.AddSingleton<IAlertManager, AlertManagerService>();
            builder.Services.AddSingleton<IScadaIntegration, ScadaIntegrationService>();
        }
    }
}
"@
Set-Content -Path $startupPath -Value $startupContent
Write-Host "  Created: Startup.cs"

# Create TelemetryProcessingFunction.cs
$telemetryFunctionPath = Join-Path -Path $functionsPath -ChildPath "TelemetryProcessingFunction.cs"
$telemetryFunctionContent = @"
// WAT.IoT.Functions/Functions/TelemetryProcessingFunction.cs
using Microsoft.Azure.WebJobs;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using System.Collections.Generic;
using System.Text;
using WAT.IoT.Core.Models;

namespace WAT.IoT.Functions.Functions
{
    public class TelemetryProcessingFunction
    {
        private readonly IConfiguration _configuration;
        private readonly ILogger<TelemetryProcessingFunction> _logger;
        private readonly HttpClient _httpClient;
        
        public TelemetryProcessingFunction(
            IConfiguration configuration,
            ILogger<TelemetryProcessingFunction> logger,
            IHttpClientFactory httpClientFactory)
        {
            _configuration = configuration;
            _logger = logger;
            _httpClient = httpClientFactory.CreateClient();
        }

        [FunctionName("ProcessTelemetry")]
        public async Task Run(
            [EventHubTrigger("telemetry", Connection = "EventHubConnection")] string[] events,
            [CosmosDB(
                databaseName: "%CosmosDbName%",
                containerName: "%TelemetryContainer%",
                Connection = "CosmosDbConnection")] IAsyncCollector<TelemetryReading> telemetryCollector,
            ILogger log)
        {
            log.LogInformation($"Processing {events.Length} telemetry events");

            foreach (var eventData in events)
            {
                try
                {
                    // Deserialize the telemetry event
                    var telemetry = JsonConvert.DeserializeObject<TelemetryReading>(eventData);
                    
                    if (telemetry == null)
                    {
                        log.LogWarning("Failed to deserialize telemetry event");
                        continue;
                    }
                    
                    // Save to Cosmos DB
                    await telemetryCollector.AddAsync(telemetry);
                    
                    // Check for alerts
                    await CheckForAlertsAsync(telemetry, log);
                    
                    log.LogInformation($"Processed telemetry for device {telemetry.DeviceId}");
                }
                catch (Exception ex)
                {
                    log.LogError(ex, "Error processing telemetry event: {EventData}", eventData);
                }
            }
        }

        private async Task CheckForAlertsAsync(TelemetryReading telemetry, ILogger log)
        {
            var alerts = new List<Alert>();
            
            // Water level alerts
            if (telemetry.WaterLevelStatus == WaterLevelStatus.High || telemetry.WaterLevelStatus == WaterLevelStatus.Critical)
            {
                alerts.Add(new Alert
                {
                    DeviceId = telemetry.DeviceId,
                    Type = AlertType.HighWaterLevel,
                    Severity = telemetry.WaterLevelStatus == WaterLevelStatus.Critical ? 
                        AlertSeverity.Emergency : AlertSeverity.Warning,
                    Message = $"High water level detected: {telemetry.WaterLevelStatus}",
                    Timestamp = DateTime.UtcNow
                });
            }
            else if (telemetry.WaterLevelStatus == WaterLevelStatus.Low)
            {
                alerts.Add(new Alert
                {
                    DeviceId = telemetry.DeviceId,
                    Type = AlertType.LowWaterLevel,
                    Severity = AlertSeverity.Warning,
                    Message = "Low water level detected",
                    Timestamp = DateTime.UtcNow
                });
            }
            
            // Water pressure alerts
            double highPressureThreshold = double.Parse(_configuration["AlertThresholds:HighPressure"] ?? "100.0");
            double lowPressureThreshold = double.Parse(_configuration["AlertThresholds:LowPressure"] ?? "10.0");
            
            if (telemetry.WaterPressure > highPressureThreshold)
            {
                alerts.Add(new Alert
                {
                    DeviceId = telemetry.DeviceId,
                    Type = AlertType.HighPressure,
                    Severity = AlertSeverity.Warning,
                    Message = $"High water pressure detected: {telemetry.WaterPressure} Pa",
                    Timestamp = DateTime.UtcNow
                });
            }
            else if (telemetry.WaterPressure < lowPressureThreshold)
            {
                alerts.Add(new Alert
                {
                    DeviceId = telemetry.DeviceId,
                    Type = AlertType.LowPressure,
                    Severity = AlertSeverity.Warning,
                    Message = $"Low water pressure detected: {telemetry.WaterPressure} Pa",
                    Timestamp = DateTime.UtcNow
                });
            }
            
            // Water quality alerts
            double waterQualityThreshold = double.Parse(_configuration["AlertThresholds:WaterQuality"] ?? "50.0");
            
            if (telemetry.WaterQuality < waterQualityThreshold)
            {
                alerts.Add(new Alert
                {
                    DeviceId = telemetry.DeviceId,
                    Type = AlertType.PoorWaterQuality,
                    Severity = telemetry.WaterQuality < waterQualityThreshold / 2 ? 
                        AlertSeverity.Critical : AlertSeverity.Warning,
                    Message = $"Poor water quality detected: {telemetry.WaterQuality}",
                    Timestamp = DateTime.UtcNow
                });
            }
            
            // Battery level alerts
            double batteryLowThreshold = double.Parse(_configuration["AlertThresholds:BatteryLow"] ?? "15.0");
            
            if (telemetry.BatteryLevel < batteryLowThreshold)
            {
                alerts.Add(new Alert
                {
                    DeviceId = telemetry.DeviceId,
                    Type = AlertType.BatteryLow,
                    Severity = telemetry.BatteryLevel < batteryLowThreshold / 2 ? 
                        AlertSeverity.Critical : AlertSeverity.Warning,
                    Message = $"Low battery level detected: {telemetry.BatteryLevel}%",
                    Timestamp = DateTime.UtcNow
                });
            }
            
            // Send alerts to event hub
            if (alerts.Count > 0)
            {
                string alertsApiUrl = _configuration["AlertsApiUrl"];
                string apiKey = _configuration["ApiKey"];
                
                if (!string.IsNullOrEmpty(alertsApiUrl) && !string.IsNullOrEmpty(apiKey))
                {
                    try
                    {
                        _httpClient.DefaultRequestHeaders.Clear();
                        _httpClient.DefaultRequestHeaders.Add("X-API-Key", apiKey);
                        
                        foreach (var alert in alerts)
                        {
                            var content = new StringContent(
                                JsonConvert.SerializeObject(alert),
                                Encoding.UTF8,
                                "application/json");
                            
                            var response = await _httpClient.PostAsync(alertsApiUrl, content);
                            
                            if (!response.IsSuccessStatusCode)
                            {
                                log.LogWarning($"Failed to send alert to API. Status: {response.StatusCode}");
                            }
                        }
                    }
                    catch (Exception ex)
                    {
                        log.LogError(ex, "Error sending alerts to API");
                    }
                }
                else
                {
                    log.LogWarning("Alert API URL or API Key not configured");
                }
            }
        }
    }
}
"@
Set-Content -Path $telemetryFunctionPath -Value $telemetryFunctionContent
Write-Host "  Created: TelemetryProcessingFunction.cs"

# Create AlertProcessingFunction.cs
$alertFunctionPath = Join-Path -Path $functionsPath -ChildPath "AlertProcessingFunction.cs"
$alertFunctionContent = @"
// WAT.IoT.Functions/Functions/AlertProcessingFunction.cs
using Microsoft.Azure.Cosmos;
using Microsoft.Azure.WebJobs;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using System.Net.Http.Headers;
using System.Text;
using WAT.IoT.Core.Models;

namespace WAT.IoT.Functions.Functions
{
    public class AlertProcessingFunction
    {
        private readonly IConfiguration _configuration;
        private readonly HttpClient _httpClient;
        
        public AlertProcessingFunction(
            IConfiguration configuration,
            IHttpClientFactory httpClientFactory)
        {
            _configuration = configuration;
            _httpClient = httpClientFactory.CreateClient();
        }

        [FunctionName("ProcessAlert")]
        public async Task Run(
            [CosmosDBTrigger(
                databaseName: "%CosmosDbName%",
                containerName: "%EventsContainer%",
                Connection = "CosmosDbConnection",
                LeaseContainerName = "leases",
                CreateLeaseContainerIfNotExists = true)] IReadOnlyList<Alert> alerts,
            ILogger log)
        {
            if (alerts == null || alerts.Count == 0)
            {
                return;
            }
            
            log.LogInformation($"Processing {alerts.Count} alerts");
            
            string scadaApiUrl = _configuration["ScadaIntegration:ScadaApiBaseUrl"];
            string alertEndpoint = _configuration["ScadaIntegration:AlertEndpoint"];
            string apiKey = _configuration["ScadaIntegration:ApiKey"];
            
            if (string.IsNullOrEmpty(scadaApiUrl) || string.IsNullOrEmpty(alertEndpoint))
            {
                log.LogWarning("SCADA API URL or Alert Endpoint not configured");
                return;
            }
            
            _httpClient.DefaultRequestHeaders.Clear();
            _httpClient.DefaultRequestHeaders.Accept.Add(new MediaTypeWithQualityHeaderValue("application/json"));
            
            if (!string.IsNullOrEmpty(apiKey))
            {
                _httpClient.DefaultRequestHeaders.Add("X-API-Key", apiKey);
            }
            
            foreach (var alert in alerts)
            {
                try
                {
                    // Only process new, unacknowledged alerts
                    if (alert.Acknowledged)
                    {
                        continue;
                    }
                    
                    log.LogInformation($"Sending alert {alert.AlertId} to SCADA system");
                    
                    var content = new StringContent(
                        JsonConvert.SerializeObject(alert),
                        Encoding.UTF8,
                        "application/json");
                    
                    string url = $"{scadaApiUrl.TrimEnd('/')}/{alertEndpoint.TrimStart('/')}";
                    var response = await _httpClient.PostAsync(url, content);
                    
                    if (response.IsSuccessStatusCode)
                    {
                        log.LogInformation($"Successfully sent alert {alert.AlertId} to SCADA system");
                    }
                    else
                    {
                        log.LogWarning($"Failed to send alert {alert.AlertId} to SCADA system. Status: {response.StatusCode}");
                    }
                    
                    // For critical or emergency alerts, also send SMS/Email notification
                    if (alert.Severity == AlertSeverity.Critical || alert.Severity == AlertSeverity.Emergency)
                    {
                        await SendNotificationAsync(alert, log);
                    }
                }
                catch (Exception ex)
                {
                    log.LogError(ex, $"Error processing alert {alert.AlertId}");
                }
            }
        }

        private async Task SendNotificationAsync(Alert alert, ILogger log)
        {
            try
            {
                string notificationApiUrl = _configuration["NotificationApiUrl"];
                
                if (string.IsNullOrEmpty(notificationApiUrl))
                {
                    log.LogWarning("Notification API URL not configured");
                    return;
                }
                
                var notification = new
                {
                    Recipients = new[] { "operations@wattreatment.com" },
                    Subject = $"WAT ALERT: {alert.Severity} - {alert.Type}",
                    Message = $"Device: {alert.DeviceId}\nType: {alert.Type}\nSeverity: {alert.Severity}\nTime: {alert.Timestamp}\nMessage: {alert.Message}",
                    AlertId = alert.AlertId
                };
                
                var content = new StringContent(
                    JsonConvert.SerializeObject(notification),
                    Encoding.UTF8,
                    "application/json");
                
                var response = await _httpClient.PostAsync(notificationApiUrl, content);
                
                if (response.IsSuccessStatusCode)
                {
                    log.LogInformation($"Successfully sent notification for alert {alert.AlertId}");
                }
                else
                {
                    log.LogWarning($"Failed to send notification for alert {alert.AlertId}. Status: {response.StatusCode}");
                }
            }
            catch (Exception ex)
            {
                log.LogError(ex, $"Error sending notification for alert {alert.AlertId}");
            }
        }
    }
}
"@
Set-Content -Path $alertFunctionPath -Value $alertFunctionContent
Write-Host "  Created: AlertProcessingFunction.cs"

# Create WaterQualityReportFunction.cs
$waterQualityFunctionPath = Join-Path -Path $functionsPath -ChildPath "WaterQualityReportFunction.cs"
$waterQualityFunctionContent = @"
// WAT.IoT.Functions/Functions/WaterQualityReportFunction.cs
using Microsoft.Azure.WebJobs;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using System.Collections.Generic;
using WAT.IoT.Core.Models;

namespace WAT.IoT.Functions.Functions
{
    public class WaterQualityReportFunction
    {
        private readonly IConfiguration _configuration;
        
        public WaterQualityReportFunction(IConfiguration configuration)
        {
            _configuration = configuration;
        }

        [FunctionName("GenerateWaterQualityReport")]
        public async Task Run(
            [TimerTrigger("0 0 0 * * *")] TimerInfo myTimer, // Run daily at midnight
            [CosmosDB(
                databaseName: "%CosmosDbName%",
                containerName: "%TelemetryContainer%",
                Connection = "CosmosDbConnection",
                SqlQuery = "SELECT * FROM c WHERE c._ts > {PastDay} ORDER BY c.deviceId, c.timestamp DESC")] IEnumerable<TelemetryReading> telemetryReadings,
            [CosmosDB(
                databaseName: "%CosmosDbName%",
                containerName: "%WaterQualityContainer%",
                Connection = "CosmosDbConnection")] IAsyncCollector<WaterQualityReport> reportCollector,
            ILogger log)
        {
            log.LogInformation($"Water Quality Report function executed at: {DateTime.Now}");
            
            // Group telemetry by device ID
            var deviceReadings = telemetryReadings
                .GroupBy(t => t.DeviceId)
                .ToDictionary(g => g.Key, g => g.ToList());
            
            foreach (var device in deviceReadings)
            {
                try
                {
                    var deviceId = device.Key;
                    var readings = device.Value;
                    
                    log.LogInformation($"Generating water quality report for device {deviceId} with {readings.Count} readings");
                    
                    // Calculate average water quality metrics
                    var avgQuality = readings.Average(t => t.WaterQuality);
                    var latestReading = readings.OrderByDescending(t => t.Timestamp).First();
                    
                    // Quality thresholds
                    double waterQualityThreshold = double.Parse(_configuration["WaterQuality:MinimumAcceptable"] ?? "70.0");
                    
                    // Generate a water quality report
                    var report = new WaterQualityReport
                    {
                        DeviceId = deviceId,
                        Timestamp = DateTime.UtcNow,
                        OverallQualityScore = avgQuality,
                        PH = 7.2, // Mock value, should be derived from actual sensors
                        Turbidity = 0.5, // Mock value, should be derived from actual sensors
                        DissolvedOxygen = 8.5, // Mock value, should be derived from actual sensors
                        TotalDissolvedSolids = 150, // Mock value, should be derived from actual sensors
                        Conductivity = 320, // Mock value, should be derived from actual sensors
                        Temperature = latestReading.Temperature,
                        ChlorineLevels = 1.2, // Mock value, should be derived from actual sensors
                        MeetsRegulationStandards = avg
						# Continue from the WaterQualityReportFunction.cs function that was cut off
Quality = avgQuality,
                        MeetsRegulationStandards = avgQuality >= waterQualityThreshold
                    };
                    
                    // Add some contaminants based on quality score
                    if (avgQuality < 95)
                    {
                        report.Contaminants.Add(new WaterContaminant
                        {
                            Name = "Total Coliform",
                            Concentration = 2.5,
                            Unit = "cfu/100mL",
                            MaxAllowedConcentration = 5.0
                        });
                    }
                    
                    if (avgQuality < 85)
                    {
                        report.Contaminants.Add(new WaterContaminant
                        {
                            Name = "Lead",
                            Concentration = 0.011,
                            Unit = "mg/L",
                            MaxAllowedConcentration = 0.015
                        });
                    }
                    
                    if (avgQuality < 70)
                    {
                        report.Contaminants.Add(new WaterContaminant
                        {
                            Name = "Nitrates",
                            Concentration = 11.5,
                            Unit = "mg/L",
                            MaxAllowedConcentration = 10.0
                        });
                    }
                    
                    // Save the report to Cosmos DB
                    await reportCollector.AddAsync(report);
                    
                    log.LogInformation($"Water quality report generated for device {deviceId}. Quality score: {avgQuality}");
                }
                catch (Exception ex)
                {
                    log.LogError(ex, $"Error generating water quality report for device {device.Key}");
                }
            }
        }
    }
}
"@
Set-Content -Path $waterQualityFunctionPath -Value $waterQualityFunctionContent
Write-Host "  Created: WaterQualityReportFunction.cs"

# Create DeviceConnectionMonitorFunction.cs
$deviceMonitorFunctionPath = Join-Path -Path $functionsPath -ChildPath "DeviceConnectionMonitorFunction.cs"
$deviceMonitorFunctionContent = @"
// WAT.IoT.Functions/Functions/DeviceConnectionMonitorFunction.cs
using Microsoft.Azure.Devices;
using Microsoft.Azure.WebJobs;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using System.Collections.Generic;
using System.Net.Http.Headers;
using System.Text;
using WAT.IoT.Core.Interfaces;
using WAT.IoT.Core.Models;

namespace WAT.IoT.Functions.Functions
{
    public class DeviceConnectionMonitorFunction
    {
        private readonly IConfiguration _configuration;
        private readonly HttpClient _httpClient;
        private readonly RegistryManager _registryManager;
        
        public DeviceConnectionMonitorFunction(
            IConfiguration configuration,
            IHttpClientFactory httpClientFactory)
        {
            _configuration = configuration;
            _httpClient = httpClientFactory.CreateClient();
            
            string iotHubConnectionString = _configuration["IoTHubConnectionString"];
            _registryManager = RegistryManager.CreateFromConnectionString(iotHubConnectionString);
        }

        [FunctionName("MonitorDeviceConnections")]
        public async Task Run(
            [TimerTrigger("0 */15 * * * *")] TimerInfo myTimer, // Run every 15 minutes
            ILogger log)
        {
            log.LogInformation($"Device Connection Monitor function executed at: {DateTime.Now}");
            
            try
            {
                // Get all devices
                var query = _registryManager.CreateQuery("SELECT * FROM devices", 100);
                var devices = new List<DeviceInfo>();
                
                while (query.HasMoreResults)
                {
                    var page = await query.GetNextAsTwinAsync();
                    foreach (var twin in page)
                    {
                        var device = new DeviceInfo
                        {
                            DeviceId = twin.DeviceId,
                            LastActivityTime = twin.LastActivityTime ?? DateTime.MinValue
                        };
                        
                        devices.Add(device);
                    }
                }
                
                log.LogInformation($"Checking connection status for {devices.Count} devices");
                
                // Check for devices that haven't communicated recently (1 hour)
                var inactiveThreshold = DateTime.UtcNow.AddHours(-1);
                var inactiveDevices = devices.Where(d => d.LastActivityTime < inactiveThreshold).ToList();
                
                if (inactiveDevices.Any())
                {
                    log.LogWarning($"Found {inactiveDevices.Count} inactive devices");
                    
                    // Create alerts for inactive devices
                    foreach (var device in inactiveDevices)
                    {
                        var alert = new Alert
                        {
                            DeviceId = device.DeviceId,
                            Type = AlertType.DeviceOffline,
                            Severity = AlertSeverity.Warning,
                            Message = $"Device has been offline since {device.LastActivityTime}",
                            Timestamp = DateTime.UtcNow
                        };
                        
                        await SendAlertAsync(alert, log);
                    }
                }
                else
                {
                    log.LogInformation("All devices are active");
                }
            }
            catch (Exception ex)
            {
                log.LogError(ex, "Error monitoring device connections");
            }
        }

        private async Task SendAlertAsync(Alert alert, ILogger log)
        {
            try
            {
                string alertsApiUrl = _configuration["AlertsApiUrl"];
                string apiKey = _configuration["ApiKey"];
                
                if (string.IsNullOrEmpty(alertsApiUrl) || string.IsNullOrEmpty(apiKey))
                {
                    log.LogWarning("Alerts API URL or API Key not configured");
                    return;
                }
                
                _httpClient.DefaultRequestHeaders.Clear();
                _httpClient.DefaultRequestHeaders.Accept.Add(new MediaTypeWithQualityHeaderValue("application/json"));
                _httpClient.DefaultRequestHeaders.Add("X-API-Key", apiKey);
                
                var content = new StringContent(
                    JsonConvert.SerializeObject(alert),
                    Encoding.UTF8,
                    "application/json");
                
                var response = await _httpClient.PostAsync(alertsApiUrl, content);
                
                if (response.IsSuccessStatusCode)
                {
                    log.LogInformation($"Successfully sent offline device alert for {alert.DeviceId}");
                }
                else
                {
                    log.LogWarning($"Failed to send offline device alert. Status: {response.StatusCode}");
                }
            }
            catch (Exception ex)
            {
                log.LogError(ex, $"Error sending offline device alert for {alert.DeviceId}");
            }
        }
    }
}
"@
Set-Content -Path $deviceMonitorFunctionPath -Value $deviceMonitorFunctionContent
Write-Host "  Created: DeviceConnectionMonitorFunction.cs"

Write-Host "Functions projects created successfully" -ForegroundColor Green
#endregion

#region Create Web Projects
Write-Host "Creating Web projects..." -ForegroundColor Cyan

$projectPath = Join-Path -Path $outputPath -ChildPath "src\WAT.IoT.Web"
$projectFile = Join-Path -Path $projectPath -ChildPath "WAT.IoT.Web.csproj"

# Create Web project if it doesn't exist
if (-not (Test-Path $projectFile)) {
    Set-Location $projectPath
    & dotnet new mvc
    
    # Update Web project file with required packages
    $projectContent = @"
<Project Sdk="Microsoft.NET.Sdk.Web">

  <PropertyGroup>
    <TargetFramework>net6.0</TargetFramework>
    <Nullable>enable</Nullable>
    <ImplicitUsings>enable</ImplicitUsings>
  </PropertyGroup>

  <ItemGroup>
    <PackageReference Include="Microsoft.ApplicationInsights.AspNetCore" Version="2.21.0" />
    <PackageReference Include="Microsoft.AspNetCore.Authentication.JwtBearer" Version="6.0.21" />
    <PackageReference Include="Microsoft.AspNetCore.Authentication.OpenIdConnect" Version="6.0.21" />
    <PackageReference Include="Microsoft.Identity.Web" Version="2.13.2" />
    <PackageReference Include="Microsoft.Identity.Web.UI" Version="2.13.2" />
  </ItemGroup>

  <ItemGroup>
    <ProjectReference Include="..\WAT.IoT.Core\WAT.IoT.Core.csproj" />
  </ItemGroup>

</Project>
"@
    
    Set-Content -Path $projectFile -Value $projectContent
    Write-Host "  Created project: WAT.IoT.Web"
    
    # Add project to solution
    Set-Location $outputPath
    & dotnet sln add "src\WAT.IoT.Web\WAT.IoT.Web.csproj"
}

# Complete DashboardViewModel.cs
$dashboardViewModelPath = Join-Path -Path (Join-Path -Path $projectPath -ChildPath "Models") -ChildPath "DashboardViewModel.cs"
$dashboardViewModelContent = @"
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
"@
Set-Content -Path $dashboardViewModelPath -Value $dashboardViewModelContent
Write-Host "  Created: DashboardViewModel.cs"

# Create Views\Home\Index.cshtml
$homeViewsPath = Join-Path -Path $projectPath -ChildPath "Views\Home"
$indexPath = Join-Path -Path $homeViewsPath -ChildPath "Index.cshtml"
$indexContent = @"
@model DashboardViewModel
@{
    ViewData["Title"] = "Dashboard";
}

<div class="text-center">
    <h1 class="display-4">Water Treatment IoT Platform</h1>
    <p>Real-time monitoring and control for water treatment facilities.</p>
</div>

<div class="row mb-4">
    <div class="col-md-3">
        <div class="card bg-primary text-white">
            <div class="card-body text-center">
                <h2>@Model.TotalDevices</h2>
                <p class="mb-0">Total Devices</p>
            </div>
        </div>
    </div>
    <div class="col-md-3">
        <div class="card bg-success text-white">
            <div class="card-body text-center">
                <h2>@Model.OnlineDevices</h2>
                <p class="mb-0">Online Devices</p>
            </div>
        </div>
    </div>
    <div class="col-md-3">
        <div class="card bg-danger text-white">
            <div class="card-body text-center">
                <h2>@Model.ActiveAlerts</h2>
                <p class="mb-0">Active Alerts</p>
            </div>
        </div>
    </div>
    <div class="col-md-3">
        <div class="card bg-info text-white">
            <div class="card-body text-center">
                <h2>@Model.AverageWaterQuality.ToString("F1")</h2>
                <p class="mb-0">Avg. Water Quality</p>
            </div>
        </div>
    </div>
</div>

<div class="row">
    <div class="col-md-6">
        <div class="card mb-4">
            <div class="card-header bg-primary text-white">
                <h5 class="mb-0">Recent Devices</h5>
            </div>
            <div class="card-body">
                <div class="table-responsive">
                    <table class="table table-striped">
                        <thead>
                            <tr>
                                <th>Device ID</th>
                                <th>Location</th>
                                <th>Status</th>
                                <th>Last Activity</th>
                            </tr>
                        </thead>
                        <tbody>
                            @foreach (var device in Model.RecentDevices)
                            {
                                <tr>
                                    <td><a asp-controller="Devices" asp-action="Details" asp-route-id="@device.DeviceId">@device.DeviceId</a></td>
                                    <td>@device.Location</td>
                                    <td>
                                        @if (device.IsActive)
                                        {
                                            <span class="badge bg-success">Online</span>
                                        }
                                        else
                                        {
                                            <span class="badge bg-danger">Offline</span>
                                        }
                                    </td>
                                    <td>@device.LastActivityTime.ToString("yyyy-MM-dd HH:mm:ss")</td>
                                </tr>
                            }
                        </tbody>
                    </table>
                </div>
                <div class="text-end">
                    <a asp-controller="Devices" asp-action="Index" class="btn btn-sm btn-primary">View All Devices</a>
                </div>
            </div>
        </div>
    </div>
    <div class="col-md-6">
        <div class="card mb-4">
            <div class="card-header bg-danger text-white">
                <h5 class="mb-0">Recent Alerts</h5>
            </div>
            <div class="card-body">
                <div class="table-responsive">
                    <table class="table table-striped">
                        <thead>
                            <tr>
                                <th>Device ID</th>
                                <th>Type</th>
                                <th>Severity</th>
                                <th>Time</th>
                            </tr>
                        </thead>
                        <tbody>
                            @foreach (var alert in Model.RecentAlerts)
                            {
                                <tr>
                                    <td><a asp-controller="Devices" asp-action="Details" asp-route-id="@alert.DeviceId">@alert.DeviceId</a></td>
                                    <td>@alert.Type</td>
                                    <td>
                                        @if (alert.Severity == AlertSeverity.Critical || alert.Severity == AlertSeverity.Emergency)
                                        {
                                            <span class="badge bg-danger">@alert.Severity</span>
                                        }
                                        else if (alert.Severity == AlertSeverity.Warning)
                                        {
                                            <span class="badge bg-warning text-dark">@alert.Severity</span>
                                        }
                                        else
                                        {
                                            <span class="badge bg-info">@alert.Severity</span>
                                        }
                                    </td>
                                    <td>@alert.Timestamp.ToString("yyyy-MM-dd HH:mm:ss")</td>
                                </tr>
                            }
                        </tbody>
                    </table>
                </div>
                <div class="text-end">
                    <a asp-controller="Alerts" asp-action="Index" class="btn btn-sm btn-primary">View All Alerts</a>
                </div>
            </div>
        </div>
    </div>
</div>

@if (Model.ActiveFloodEvents.Any())
{
    <div class="row">
        <div class="col-12">
            <div class="card mb-4">
                <div class="card-header bg-danger text-white">
                    <h5 class="mb-0">Active Flood Events</h5>
                </div>
                <div class="card-body">
                    <div class="table-responsive">
                        <table class="table table-striped">
                            <thead>
                                <tr>
                                    <th>Location</th>
                                    <th>Severity</th>
                                    <th>Start Time</th>
                                    <th>Affected Devices</th>
                                    <th>Actions</th>
                                </tr>
                            </thead>
                            <tbody>
                                @foreach (var floodEvent in Model.ActiveFloodEvents)
                                {
                                    <tr>
                                        <td>@floodEvent.Location</td>
                                        <td>
                                            @if (floodEvent.Severity == FloodSeverity.Catastrophic || floodEvent.Severity == FloodSeverity.Major)
                                            {
                                                <span class="badge bg-danger">@floodEvent.Severity</span>
                                            }
                                            else if (floodEvent.Severity == FloodSeverity.Moderate)
                                            {
                                                <span class="badge bg-warning text-dark">@floodEvent.Severity</span>
                                            }
                                            else
                                            {
                                                <span class="badge bg-info">@floodEvent.Severity</span>
                                            }
                                        </td>
                                        <td>@floodEvent.StartTime.ToString("yyyy-MM-dd HH:mm:ss")</td>
                                        <td>@floodEvent.AffectedDeviceIds.Count</td>
                                        <td>
                                            <a asp-controller="FloodEvents" asp-action="Details" asp-route-id="@floodEvent.EventId" class="btn btn-sm btn-primary">Details</a>
                                        </td>
                                    </tr>
                                }
                            </tbody>
                        </table>
                    </div>
                    <div class="text-end">
                        <a asp-controller="FloodEvents" asp-action="Index" class="btn btn-sm btn-primary">View All Flood Events</a>
                    </div>
                </div>
            </div>
        </div>
    </div>
}
"@
Set-Content -Path $indexPath -Value $indexContent
Write-Host "  Created: Index.cshtml (Home)"

# Create shared views directory
$sharedViewsPath = Join-Path -Path $projectPath -ChildPath "Views\Shared"
if (-not (Test-Path $sharedViewsPath)) {
    New-Item -ItemType Directory -Path $sharedViewsPath -Force | Out-Null
    Write-Host "  Created directory: Views\Shared"
}

# Create _LoginPartial.cshtml
$loginPartialPath = Join-Path -Path $sharedViewsPath -ChildPath "_LoginPartial.cshtml"
$loginPartialContent = @"
@using Microsoft.Identity.Web

<ul class="navbar-nav">
@if (User.Identity?.IsAuthenticated == true)
{
    <li class="nav-item">
        <span class="nav-link text-white">Hello @User.GetDisplayName()!</span>
    </li>
    <li class="nav-item">
        <a class="nav-link text-white" asp-area="MicrosoftIdentity" asp-controller="Account" asp-action="SignOut">Sign out</a>
    </li>
}
else
{
    <li class="nav-item">
        <a class="nav-link text-white" asp-area="MicrosoftIdentity" asp-controller="Account" asp-action="SignIn">Sign in</a>
    </li>
}
</ul>
"@
Set-Content -Path $loginPartialPath -Value $loginPartialContent
Write-Host "  Created: _LoginPartial.cshtml"

# Create Error.cshtml
$errorPath = Join-Path -Path $sharedViewsPath -ChildPath "Error.cshtml"
$errorContent = @"
@model ErrorViewModel
@{
    ViewData["Title"] = "Error";
}

<h1 class="text-danger">Error.</h1>
<h2 class="text-danger">An error occurred while processing your request.</h2>

@if (Model.ShowRequestId)
{
    <p>
        <strong>Request ID:</strong> <code>@Model.RequestId</code>
    </p>
}

<h3>Development Mode</h3>
<p>
    Swapping to <strong>Development</strong> environment will display more detailed information about the error that occurred.
</p>
<p>
    <strong>The Development environment shouldn't be enabled for deployed applications.</strong>
    It can result in displaying sensitive information from exceptions to end users.
    For local debugging, enable the <strong>Development</strong> environment by setting the <strong>ASPNETCORE_ENVIRONMENT</strong> environment variable to <strong>Development</strong>
    and restarting the app.
</p>
"@
Set-Content -Path $errorPath -Value $errorContent
Write-Host "  Created: Error.cshtml"

Write-Host "Web projects created successfully" -ForegroundColor Green
#endregion

#region Create Simulator Projects
# Simulator Projects were already created in the original script
Write-Host "Simulator projects already created" -ForegroundColor Green
#endregion

#region Create Test Projects
# Test Projects were already created in the original script
Write-Host "Test projects already created" -ForegroundColor Green
#endregion

#region Create Documentation
$docsPath = Join-Path -Path $outputPath -ChildPath "docs"

# Create README.md at the root
$readmePath = Join-Path -Path $outputPath -ChildPath "README.md"

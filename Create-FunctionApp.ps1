# Create-FunctionApp-Simple.ps1

# Set the base output path for the solution
$solutionPath = ".\WAT.IoT.Solution"
$functionAppPath = "$solutionPath\src\WAT.IoT.Functions"

# Create the directories if they don't exist
if (-not (Test-Path $solutionPath)) {
    New-Item -ItemType Directory -Path $solutionPath -Force | Out-Null
    Write-Host "Created solution directory: $solutionPath"
}

if (-not (Test-Path $functionAppPath)) {
    New-Item -ItemType Directory -Path $functionAppPath -Force | Out-Null
    Write-Host "Created function app directory: $functionAppPath"
}

# Install Azure Functions templates
Write-Host "Installing Azure Functions templates..." -ForegroundColor Cyan
& dotnet new install Microsoft.Azure.Functions.Worker.ProjectTemplates

# Create the Functions project
Write-Host "Creating Functions project..." -ForegroundColor Cyan
Push-Location $functionAppPath

# Try to create using the correct func template - with force flag to overwrite existing files
try {
    & dotnet new func --force
    Write-Host "  Created project using func template" -ForegroundColor Green
} 
catch {
    # If func template fails, create a standard class library and modify it
    Write-Host "  func template not found, creating class library instead" -ForegroundColor Yellow
    & dotnet new classlib --force
    
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
    
    Set-Content -Path "WAT.IoT.Functions.csproj" -Value $projectContent
}

# Create host.json
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
Set-Content -Path "host.json" -Value $hostJsonContent
Write-Host "  Created: host.json" -ForegroundColor Green

# Create local.settings.json
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
Set-Content -Path "local.settings.json" -Value $localSettingsContent
Write-Host "  Created: local.settings.json" -ForegroundColor Green

# Create Functions directory for storing function files
$functionsDir = "Functions"
if (-not (Test-Path $functionsDir)) {
    New-Item -ItemType Directory -Path $functionsDir -Force | Out-Null
    Write-Host "  Created directory: $functionsDir" -ForegroundColor Green
}

# Create a sample Azure Function
$sampleFunctionContent = @"
using Microsoft.Azure.WebJobs;
using Microsoft.Extensions.Logging;
using System;
using System.Threading.Tasks;

namespace WAT.IoT.Functions
{
    public static class SampleFunction
    {
        [FunctionName("SampleFunction")]
        public static async Task Run(
            [TimerTrigger("0 */5 * * * *")] TimerInfo myTimer, // Runs every 5 minutes
            ILogger log)
        {
            log.LogInformation($"Sample function executed at: {DateTime.Now}");
            
            // Your function logic here
            await Task.Delay(1); // Placeholder for async operation
            
            log.LogInformation("Sample function completed successfully");
        }
    }
}
"@
Set-Content -Path "$functionsDir\SampleFunction.cs" -Value $sampleFunctionContent
Write-Host "  Created: SampleFunction.cs" -ForegroundColor Green

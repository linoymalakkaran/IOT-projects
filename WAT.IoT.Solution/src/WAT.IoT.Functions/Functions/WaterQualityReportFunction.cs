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

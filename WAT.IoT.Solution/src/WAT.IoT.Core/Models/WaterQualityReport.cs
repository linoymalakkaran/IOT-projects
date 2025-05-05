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

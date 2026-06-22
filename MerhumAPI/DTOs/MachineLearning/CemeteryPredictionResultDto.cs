namespace MerhumAPI.DTOs.MachineLearning;

public class CemeteryPredictionResultDto
{
    public int CemeteryId { get; set; }
    public string CemeteryName { get; set; } = string.Empty;
    public int TotalCapacity { get; set; }
    public int CurrentOccupancy { get; set; }
    public double OccupancyPercentage { get; set; }
    public double AverageBurialsPerMonth { get; set; }
    public double PredictedMonthsUntilFull { get; set; }
    public DateTime EstimatedFullDate { get; set; }
    public string ConfidenceLevel { get; set; } = "Niska";
}

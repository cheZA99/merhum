namespace MerhumAPI.Services.MachineLearning.Models;

public class CemeteryFeatures
{
	public int CemeteryId { get; set; }
	public string CemeteryName { get; set; } = string.Empty;
	public int TotalCapacity { get; set; }
	public int CurrentOccupancy { get; set; }
	public double OccupancyPercentage { get; set; }
	public double AverageBurialsPerMonth { get; set; }
	public double MonthsUntilFull { get; set; }
	public int RealBurialCount { get; set; }
}
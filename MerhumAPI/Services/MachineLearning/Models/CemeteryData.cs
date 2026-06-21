namespace MerhumAPI.Services.MachineLearning.Models;

public class CemeteryData
{
	public float TotalCapacity { get; set; }
	public float CurrentOccupancy { get; set; }
	public float OccupancyPercentage { get; set; }
	public float AverageBurialsPerMonth { get; set; }
	public float MonthsUntilFull { get; set; }
}
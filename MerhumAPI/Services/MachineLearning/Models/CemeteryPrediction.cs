using Microsoft.ML.Data;

namespace MerhumAPI.Services.MachineLearning.Models;

public class CemeteryPrediction
{
	[ColumnName("Score")]
	public float PredictedMonthsUntilFull { get; set; }
}
namespace MerhumAPI.Services.MachineLearning.Models;

// real rows come from burial history, synthetic ones only pad a set too small to train on
public class TrainingDataSet
{
	public List<CemeteryData> Real { get; set; } = new();

	public List<CemeteryData> Synthetic { get; set; } = new();

	public int TotalCount => Real.Count + Synthetic.Count;
}

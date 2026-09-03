using MerhumAPI.Services.MachineLearning.Models;

namespace MerhumAPI.Services.MachineLearning;

public interface ITrainingDataService
{
	Task<TrainingDataSet> BuildTrainingDataAsync();

	Task<CemeteryFeatures?> GetCemeteryFeaturesAsync(int cemeteryId);
}
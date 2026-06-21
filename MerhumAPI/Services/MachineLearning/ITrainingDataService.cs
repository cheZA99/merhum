using MerhumAPI.Services.MachineLearning.Models;

namespace MerhumAPI.Services.MachineLearning;

public interface ITrainingDataService
{
	Task<List<CemeteryData>> BuildTrainingDataAsync();

	Task<CemeteryFeatures?> GetCemeteryFeaturesAsync(int cemeteryId);
}
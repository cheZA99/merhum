using MerhumAPI.DTOs.MachineLearning;

namespace MerhumAPI.Services.MachineLearning;

public interface ICemeteryPredictionService
{
    Task TrainModelAsync();
    Task<CemeteryPredictionResultDto?> PredictAsync(int cemeteryId);
    bool IsModelTrained();
}

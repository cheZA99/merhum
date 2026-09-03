using MerhumAPI.DTOs.MachineLearning;
using MerhumAPI.Services.MachineLearning.Models;
using Microsoft.ML;

namespace MerhumAPI.Services.MachineLearning;

public class CemeteryPredictionService :ICemeteryPredictionService
{
	private readonly MLContext _mlContext;
	private readonly IServiceScopeFactory _scopeFactory;
	private readonly ILogger<CemeteryPredictionService> _logger;
	private readonly SemaphoreSlim _trainLock = new(1, 1);
	private readonly string _modelPath;
	private readonly Random _splitRandom = new(42);

	private ITransformer? _model;

	public CemeteryPredictionService(
	    IServiceScopeFactory scopeFactory,
	    ILogger<CemeteryPredictionService> logger)
	{
		_scopeFactory = scopeFactory;
		_logger = logger;
		_mlContext = new MLContext(seed: 42);
		_modelPath = Path.Combine(AppContext.BaseDirectory, "model.zip");
	}

	public bool IsModelTrained() => _model != null || File.Exists(_modelPath);

	public async Task TrainModelAsync()
	{
		await _trainLock.WaitAsync();
		try
		{
			TrainingDataSet trainingData;
			using (var scope = _scopeFactory.CreateScope())
			{
				var dataService = scope.ServiceProvider.GetRequiredService<ITrainingDataService>();
				trainingData = await dataService.BuildTrainingDataAsync();
			}

			if (trainingData.TotalCount < 10)
				throw new InvalidOperationException("Not enough training data to train the model.");

			// the test set holds real history only, so the score never becomes a test of the generator
			var shuffledReal = trainingData.Real.OrderBy(_ => _splitRandom.Next()).ToList();
			var testCount = shuffledReal.Count >= 5 ? shuffledReal.Count / 5 : 0;
			var testRows = shuffledReal.Take(testCount).ToList();
			var trainRows = shuffledReal.Skip(testCount).Concat(trainingData.Synthetic).ToList();

			var dataView = _mlContext.Data.LoadFromEnumerable(trainRows);

			var pipeline = _mlContext.Transforms
			    .Concatenate(
				   "Features",
				   nameof(CemeteryData.TotalCapacity),
				   nameof(CemeteryData.CurrentOccupancy),
				   nameof(CemeteryData.OccupancyPercentage),
				   nameof(CemeteryData.AverageBurialsPerMonth))
			    .Append(_mlContext.Regression.Trainers.FastTree(
				   labelColumnName: nameof(CemeteryData.MonthsUntilFull),
				   featureColumnName: "Features"));

			var model = pipeline.Fit(dataView);

			_mlContext.Model.Save(model, dataView.Schema, _modelPath);
			_model = model;

			if (testRows.Count == 0)
			{
				_logger.LogWarning(
				    "Cemetery prediction model trained on {Real} real and {Synthetic} synthetic rows. Too little history to score it.",
				    trainingData.Real.Count, trainingData.Synthetic.Count);
				return;
			}

			var predictions = model.Transform(_mlContext.Data.LoadFromEnumerable(testRows));
			var metrics = _mlContext.Regression.Evaluate(
			    predictions, labelColumnName: nameof(CemeteryData.MonthsUntilFull));

			_logger.LogInformation(
			    "Cemetery prediction model trained on {Real} real and {Synthetic} synthetic rows, scored on {Test} real rows. R2={RSquared:F3}, RMSE={Rmse:F2}.",
			    trainingData.Real.Count, trainingData.Synthetic.Count, testRows.Count, metrics.RSquared, metrics.RootMeanSquaredError);
		}
		finally
		{
			_trainLock.Release();
		}
	}

	public async Task<CemeteryPredictionResultDto?> PredictAsync(int cemeteryId)
	{
		CemeteryFeatures? features;
		using (var scope = _scopeFactory.CreateScope())
		{
			var dataService = scope.ServiceProvider.GetRequiredService<ITrainingDataService>();
			features = await dataService.GetCemeteryFeaturesAsync(cemeteryId);
		}

		if (features == null)
			return null;

		await EnsureModelLoadedAsync();

		var engine = _mlContext.Model.CreatePredictionEngine<CemeteryData, CemeteryPrediction>(_model!);
		var input = new CemeteryData
		{
			TotalCapacity = features.TotalCapacity,
			CurrentOccupancy = features.CurrentOccupancy,
			OccupancyPercentage = (float)features.OccupancyPercentage,
			AverageBurialsPerMonth = (float)features.AverageBurialsPerMonth
		};

		var prediction = engine.Predict(input);

		// clamp to a reasonable month range
		var months = Math.Clamp(prediction.PredictedMonthsUntilFull, 0f, 1200f);

		return new CemeteryPredictionResultDto
		{
			CemeteryId = features.CemeteryId,
			CemeteryName = features.CemeteryName,
			TotalCapacity = features.TotalCapacity,
			CurrentOccupancy = features.CurrentOccupancy,
			OccupancyPercentage = features.OccupancyPercentage,
			AverageBurialsPerMonth = features.AverageBurialsPerMonth,
			PredictedMonthsUntilFull = Math.Round(months, 1),
			EstimatedFullDate = DateTime.Today.AddMonths((int)Math.Round(months)),
			ConfidenceLevel = ResolveConfidence(features.RealBurialCount)
		};
	}

	private async Task EnsureModelLoadedAsync()
	{
		if (_model != null)
			return;

		if (File.Exists(_modelPath))
		{
			using var stream = File.OpenRead(_modelPath);
			_model = _mlContext.Model.Load(stream, out _);
			return;
		}

		await TrainModelAsync();
	}

	private static string ResolveConfidence(int realBurialCount)
	{
		if (realBurialCount >= 10)
			return "Visoka";
		if (realBurialCount >= 3)
			return "Srednja";
		return "Niska";
	}
}
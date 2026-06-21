using MerhumAPI.Data;
using MerhumAPI.Services.MachineLearning.Models;
using Microsoft.EntityFrameworkCore;

namespace MerhumAPI.Services.MachineLearning;

public class TrainingDataService :ITrainingDataService
{
	private readonly ApplicationDbContext _db;

	// A cemetery is treated as full when there are no free spots, so we never
	// divide by zero and we clamp the calculated label to a sane horizon.
	private const double MaxMonthsHorizon = 600.0;

	public TrainingDataService(ApplicationDbContext db) => _db = db;

	public async Task<List<CemeteryData>> BuildTrainingDataAsync()
	{
		var data = new List<CemeteryData>();

		var cemeteries = await _db.Cemeteries.Where(c => c.IsActive).ToListAsync();
		foreach (var cemetery in cemeteries)
		{
			var features = await CalculateFeaturesAsync(cemetery.Id, cemetery.Name, cemetery.TotalPlaces);
			if (features == null)
				continue;

			// Only real rows with a usable fill rate help the model learn.
			if (features.AverageBurialsPerMonth > 0)
			{
				data.Add(new CemeteryData
				{
					TotalCapacity = features.TotalCapacity,
					CurrentOccupancy = features.CurrentOccupancy,
					OccupancyPercentage = (float)features.OccupancyPercentage,
					AverageBurialsPerMonth = (float)features.AverageBurialsPerMonth,
					MonthsUntilFull = (float)features.MonthsUntilFull
				});
			}
		}

		data.AddRange(GenerateSyntheticData(200));
		return data;
	}

	public async Task<CemeteryFeatures?> GetCemeteryFeaturesAsync(int cemeteryId)
	{
		var cemetery = await _db.Cemeteries.FirstOrDefaultAsync(c => c.Id == cemeteryId);
		if (cemetery == null)
			return null;
		return await CalculateFeaturesAsync(cemetery.Id, cemetery.Name, cemetery.TotalPlaces);
	}

	private async Task<CemeteryFeatures> CalculateFeaturesAsync(int cemeteryId, string name, int totalCapacity)
	{
		var occupancy = await _db.GraveSites
		    .CountAsync(g => g.CemeteryId == cemeteryId && g.Status == "Occupied");

		var occupancyPercentage = totalCapacity > 0
		    ? Math.Round((double)occupancy / totalCapacity * 100, 1)
		    : 0.0;

		var (averageBurialsPerMonth, realBurialCount) = await CalculateBurialRateAsync(cemeteryId);

		var freeSpots = Math.Max(0, totalCapacity - occupancy);
		var monthsUntilFull = averageBurialsPerMonth > 0
		    ? Math.Min(MaxMonthsHorizon, freeSpots / averageBurialsPerMonth)
		    : MaxMonthsHorizon;

		return new CemeteryFeatures
		{
			CemeteryId = cemeteryId,
			CemeteryName = name,
			TotalCapacity = totalCapacity,
			CurrentOccupancy = occupancy,
			OccupancyPercentage = occupancyPercentage,
			AverageBurialsPerMonth = Math.Round(averageBurialsPerMonth, 2),
			MonthsUntilFull = Math.Round(monthsUntilFull, 1),
			RealBurialCount = realBurialCount
		};
	}

	// Burial rate from completed funerals (Held appointments). Primary window is the
	// last 12 months; if there is older history but nothing recent, fall back to the
	// full span so the rate stays meaningful even with sparse data.
	private async Task<(double rate, int count)> CalculateBurialRateAsync(int cemeteryId)
	{
		var now = DateTime.UtcNow;
		var twelveMonthsAgo = now.AddMonths(-12);

		var held = await _db.Appointments
		    .Where(a => a.CemeteryId == cemeteryId && a.Status == "Held")
		    .Select(a => a.FuneralDateTime)
		    .ToListAsync();

		if (held.Count == 0)
			return (0, 0);

		var recent = held.Count(d => d >= twelveMonthsAgo);
		if (recent > 0)
			return (recent / 12.0, recent);

		var earliest = held.Min();
		var spanMonths = Math.Max(1.0, (now - earliest).TotalDays / 30.0);
		return (held.Count / spanMonths, held.Count);
	}

	private static IEnumerable<CemeteryData> GenerateSyntheticData(int rows)
	{
		// Fixed seed so training data is reproducible between runs.
		var random = new Random(42);
		var result = new List<CemeteryData>(rows);

		for (var i = 0; i < rows; i++)
		{
			float capacity = random.Next(100, 1001);
			float occupancyPercentage = random.Next(10, 96);
			float occupancy = (float)Math.Round(capacity * occupancyPercentage / 100f);
			float burialsPerMonth = random.Next(1, 16);

			var freeSpots = Math.Max(0, capacity - occupancy);
			var monthsUntilFull = freeSpots / burialsPerMonth;

			// Small noise so the model does not just memorize an exact formula.
			var noise = (float)((random.NextDouble() - 0.5) * 2.0);
			monthsUntilFull = Math.Max(0, monthsUntilFull + noise);

			result.Add(new CemeteryData
			{
				TotalCapacity = capacity,
				CurrentOccupancy = occupancy,
				OccupancyPercentage = occupancyPercentage,
				AverageBurialsPerMonth = burialsPerMonth,
				MonthsUntilFull = monthsUntilFull
			});
		}

		return result;
	}
}
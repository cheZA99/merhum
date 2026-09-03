using MerhumAPI.Data;
using MerhumAPI.Models;
using MerhumAPI.Services.MachineLearning.Models;
using Microsoft.EntityFrameworkCore;

namespace MerhumAPI.Services.MachineLearning;

public class TrainingDataService :ITrainingDataService
{
	private readonly ApplicationDbContext _db;

	private const double MaxMonthsHorizon = 600.0;
	private const int MinimumTrainingRows = 10;

	public TrainingDataService(ApplicationDbContext db) => _db = db;

	public async Task<TrainingDataSet> BuildTrainingDataAsync()
	{
		var real = new List<CemeteryData>();

		var cemeteries = await _db.Cemeteries.Where(c => c.IsActive).ToListAsync();
		foreach (var cemetery in cemeteries)
			real.AddRange(await BuildHistoryRowsAsync(cemetery));

		// synthetic rows only close the gap up to what the trainer needs, they never outnumber history by default
		var missing = MinimumTrainingRows - real.Count;
		var synthetic = missing > 0
		    ? GenerateSyntheticData(missing).ToList()
		    : new List<CemeteryData>();

		return new TrainingDataSet { Real = real, Synthetic = synthetic };
	}

	// one row per month of a cemetery's history, so the features describe the state at that month
	// and the label is built from the burial rate that actually followed it
	private async Task<List<CemeteryData>> BuildHistoryRowsAsync(Cemetery cemetery)
	{
		var rows = new List<CemeteryData>();

		var burials = await _db.Appointments
		    .Where(a => a.CemeteryId == cemetery.Id && a.Status == AppointmentStatus.Held)
		    .Select(a => a.FuneralDateTime)
		    .OrderBy(d => d)
		    .ToListAsync();

		if (burials.Count == 0 || cemetery.TotalPlaces <= 0)
			return rows;

		var occupancyNow = await _db.GraveSites
		    .CountAsync(g => g.CemeteryId == cemetery.Id && g.Status == GraveSiteStatus.Occupied);

		var now = DateTime.UtcNow;
		var firstMonth = new DateTime(burials[0].Year, burials[0].Month, 1);
		var lastMonth = new DateTime(now.Year, now.Month, 1);

		for (var month = firstMonth.AddMonths(1); month < lastMonth; month = month.AddMonths(1))
		{
			var before = burials.Count(d => d < month);
			var after = burials.Count - before;
			if (before == 0 || after == 0)
				continue;

			var monthsBefore = Math.Max(1.0, (month - firstMonth).TotalDays / 30.0);
			var monthsAfter = Math.Max(1.0, (lastMonth - month).TotalDays / 30.0);

			var occupancyThen = Math.Max(0, occupancyNow - after);
			var freeThen = Math.Max(0, cemetery.TotalPlaces - occupancyThen);
			var futureRate = after / monthsAfter;

			rows.Add(new CemeteryData
			{
				TotalCapacity = cemetery.TotalPlaces,
				CurrentOccupancy = occupancyThen,
				OccupancyPercentage = (float)Math.Round((double)occupancyThen / cemetery.TotalPlaces * 100, 1),
				AverageBurialsPerMonth = (float)Math.Round(before / monthsBefore, 2),
				MonthsUntilFull = (float)Math.Round(Math.Min(MaxMonthsHorizon, freeThen / futureRate), 1)
			});
		}

		return rows;
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
		    .CountAsync(g => g.CemeteryId == cemeteryId && g.Status == GraveSiteStatus.Occupied);

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

	// burial rate over the window that actually has data, capped at the last 12 months
	private async Task<(double rate, int count)> CalculateBurialRateAsync(int cemeteryId)
	{
		var now = DateTime.UtcNow;
		var twelveMonthsAgo = now.AddMonths(-12);

		var held = await _db.Appointments
		    .Where(a => a.CemeteryId == cemeteryId && a.Status == AppointmentStatus.Held)
		    .Select(a => a.FuneralDateTime)
		    .ToListAsync();

		if (held.Count == 0)
			return (0, 0);

		var earliest = held.Min();
		var windowStart = earliest > twelveMonthsAgo ? earliest : twelveMonthsAgo;
		var windowMonths = Math.Max(1.0, (now - windowStart).TotalDays / 30.0);
		var counted = held.Count(d => d >= windowStart);

		return (counted / windowMonths, counted);
	}

	private static IEnumerable<CemeteryData> GenerateSyntheticData(int rows)
	{
		// fixed seed for reproducible synthetic data
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
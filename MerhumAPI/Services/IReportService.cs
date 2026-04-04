namespace MerhumAPI.Services;

public interface IReportService
{
    Task<byte[]> GenerateDeceasedPdfAsync(int deceasedId);
    Task<byte[]> GenerateObituaryPdfAsync(string slug);
    Task<object> GetDashboardStatsAsync();
}

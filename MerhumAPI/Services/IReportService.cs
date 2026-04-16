namespace MerhumAPI.Services;

public interface IReportService
{
    Task<byte[]> GenerateDeceasedPdfAsync(int deceasedId);
    Task<byte[]> GenerateObituaryPdfAsync(string slug);
    Task<object> GetDashboardStatsAsync();
    Task<object> GetBurialReportAsync(int? year);
    Task<object> GetCemeteryCapacityReportAsync();
    Task<object> GetServicesReportAsync(int? year);
    Task<object> GetObituariesStatsReportAsync();
    Task<object> GetFinancialReportAsync(int? year);
}

namespace MerhumAPI.Services.Chat;

public interface IContextBuilderService
{
    Task<string> BuildContextAsync(string userId);
}

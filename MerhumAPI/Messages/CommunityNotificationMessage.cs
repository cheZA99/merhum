namespace MerhumAPI.Messages;

public record CommunityNotificationMessage(
    int DeceasedId,
    string DeceasedFullName,
    string MosqueName,
    string CemeteryName,
    DateTime FuneralDateTime,
    string ObituarySlug
);

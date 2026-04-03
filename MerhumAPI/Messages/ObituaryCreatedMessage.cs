namespace MerhumAPI.Messages;

public record ObituaryCreatedMessage(
    int ObituaryId,
    int DeceasedId,
    string DeceasedFullName,
    string UniqueSlug,
    string ContactPersonEmail,
    string ContactPersonName,
    DateTime CreatedAt
);

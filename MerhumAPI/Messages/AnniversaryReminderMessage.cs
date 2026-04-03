namespace MerhumAPI.Messages;

public record AnniversaryReminderMessage(
    int DeceasedId,
    string DeceasedFullName,
    DateOnly DateOfDeath,
    int YearsElapsed,
    string ContactPersonEmail,
    string ContactPersonName,
    string? ObituarySlug
);

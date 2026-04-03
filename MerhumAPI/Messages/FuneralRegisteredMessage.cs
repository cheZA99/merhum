namespace MerhumAPI.Messages;

public record FuneralRegisteredMessage(
    int DeceasedId,
    string FullName,
    string ContactPersonEmail,
    string ContactPersonName,
    string ContactPersonPhone,
    DateTime RegisteredAt
);

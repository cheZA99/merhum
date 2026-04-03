namespace MerhumAPI.Messages;

public record ServiceOrderedMessage(
    int ServiceOrderId,
    int DeceasedId,
    string DeceasedFullName,
    string FuneralHomeName,
    string ServiceTypeName,
    decimal Price,
    string FuneralHomeEmail,
    DateTime OrderedAt
);

namespace MerhumWorker.Messages;

public record PaymentCompletedMessage(
    int PaymentId,
    int ServiceOrderId,
    string ServiceTypeName,
    decimal Amount,
    string Currency,
    string RecipientName,
    string RecipientEmail,
    DateTime CompletedAt
);

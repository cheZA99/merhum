namespace MerhumContracts;

public record PasswordResetRequestedMessage(
    string UserId,
    string FullName,
    string Email,
    string Token,
    DateTime RequestedAt
);

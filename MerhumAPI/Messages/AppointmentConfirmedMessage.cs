namespace MerhumAPI.Messages;

public record AppointmentConfirmedMessage(
    int AppointmentId,
    int DeceasedId,
    string DeceasedFullName,
    string MosqueName,
    string CemeteryName,
    string? ImamFullName,
    DateTime FuneralDateTime,
    string ContactPersonEmail,
    string ContactPersonPhone
);

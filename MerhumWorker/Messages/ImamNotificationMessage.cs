namespace MerhumWorker.Messages;

public record ImamNotificationMessage(
    int ImamId,
    string ImamFullName,
    string ImamEmail,
    int AppointmentId,
    string DeceasedFullName,
    string MosqueName,
    string CemeteryName,
    DateTime FuneralDateTime
);

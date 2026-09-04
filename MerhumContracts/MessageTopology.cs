namespace MerhumContracts;

// exchange and queue names, shared so the publisher and the consumer cannot drift apart
public static class MessageTopology
{
    public const string FuneralRegistered = "merhum.prijavljen";
    public const string AppointmentConfirmed = "merhum.termin.potvrden";
    public const string ServiceOrdered = "merhum.usluge.narudzba";
    public const string ImamNotification = "merhum.imam.obavjestenje";
    public const string CommunityNotification = "merhum.dzemat.notifikacija";
    public const string ObituaryCreated = "merhum.smrtovnica.kreirana";
    public const string AnniversaryReminder = "merhum.godisnjica";
    public const string PaymentCompleted = "merhum.placanje.izvrseno";
    public const string PasswordResetRequested = "merhum.lozinka.reset";
}

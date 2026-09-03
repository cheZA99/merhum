namespace MerhumAPI.Common;

// the roles the application knows about, kept here so seeding and validation cannot drift apart
public static class Roles
{
    public const string Administrator = "Administrator";
    public const string Porodica = "Porodica";
    public const string JavniKorisnik = "JavniKorisnik";
    public const string Imam = "Imam";
    public const string PogrebnoPreduzece = "PogrebnoPreduzeće";

    public static readonly string[] All =
    {
        Administrator, Porodica, JavniKorisnik, Imam, PogrebnoPreduzece
    };
}

using System.Globalization;
using System.Text;
using MerhumAPI.Data;
using MerhumAPI.Models;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;

namespace MerhumAPI.Services.Chat;

public class ContextBuilderService : IContextBuilderService
{
    private readonly ApplicationDbContext _db;
    private readonly UserManager<ApplicationUser> _userManager;

    public ContextBuilderService(ApplicationDbContext db, UserManager<ApplicationUser> userManager)
    {
        _db = db;
        _userManager = userManager;
    }

    public async Task<string> BuildContextAsync(string userId)
    {
        var sb = new StringBuilder();
        var culture = CultureInfo.InvariantCulture;

        var user = await _db.Users
            .Include(u => u.City)
            .FirstOrDefaultAsync(u => u.Id == userId);

        if (user == null)
        {
            sb.AppendLine("KORISNIK: Nepoznat");
            return sb.ToString();
        }

        var roles = await _userManager.GetRolesAsync(user);
        var roleText = roles.Count > 0 ? string.Join(", ", roles) : "Nepoznata uloga";
        var cityName = user.City?.Name ?? "Nije postavljen";

        sb.AppendLine("KORISNIK:");
        sb.AppendLine($"- Ime: {user.FullName}");
        sb.AppendLine($"- Grad: {cityName}");
        sb.AppendLine($"- Uloga: {roleText}");
        sb.AppendLine();

        var cemeteryQuery = _db.Cemeteries
            .Include(c => c.City)
            .Where(c => c.IsActive);

        if (user.CityId.HasValue)
            cemeteryQuery = cemeteryQuery.Where(c => c.CityId == user.CityId.Value);

        var cemeteries = await cemeteryQuery.Take(10).ToListAsync();

        sb.AppendLine("DOSTUPNA GROBLJA:");
        if (cemeteries.Count == 0)
        {
            sb.AppendLine("- Nema dostupnih groblja u Vašem gradu.");
        }
        else
        {
            foreach (var c in cemeteries)
            {
                var free = await _db.GraveSites.CountAsync(g => g.CemeteryId == c.Id && g.Status == "Available");
                var occupancy = c.TotalPlaces > 0
                    ? Math.Round(((double)(c.TotalPlaces - free) / c.TotalPlaces) * 100.0, 1)
                    : 0.0;
                sb.AppendLine($"- {c.Name} ({c.City.Name}) – ukupno mjesta: {c.TotalPlaces}, slobodno: {free}, popunjenost: {occupancy.ToString(culture)}%");
            }
        }
        sb.AppendLine();

        var mosqueQuery = _db.Mosques
            .Include(m => m.City)
            .Include(m => m.Imams)
            .Where(m => m.IsActive);

        if (user.CityId.HasValue)
            mosqueQuery = mosqueQuery.Where(m => m.CityId == user.CityId.Value);

        var mosques = await mosqueQuery.Take(10).ToListAsync();

        sb.AppendLine("DŽAMIJE I IMAMI:");
        if (mosques.Count == 0)
        {
            sb.AppendLine("- Nema podataka o džamijama u Vašem gradu.");
        }
        else
        {
            foreach (var m in mosques)
            {
                var imamNames = m.Imams.Where(i => i.IsActive).Select(i => $"{i.FirstName} {i.LastName}").ToList();
                var imamText = imamNames.Count > 0 ? string.Join(", ", imamNames) : "nema dostupnih imama";
                sb.AppendLine($"- {m.Name} ({m.City.Name}) – imami: {imamText}");
            }
        }
        sb.AppendLine();

        var statuses = await _db.ProcedureStatuses.OrderBy(s => s.SortOrder).ToListAsync();
        sb.AppendLine("FAZE PROCEDURE:");
        if (statuses.Count == 0)
        {
            sb.AppendLine("- Nema definisanih faza.");
        }
        else
        {
            foreach (var s in statuses)
            {
                sb.AppendLine($"- {s.Name}");
            }
        }
        sb.AppendLine();

        var serviceOrders = await _db.ServiceOrders
            .Include(o => o.ServiceType)
            .GroupBy(o => o.ServiceType.Name)
            .Select(g => new { Name = g.Key, AvgPrice = g.Average(x => x.Price) })
            .ToListAsync();

        sb.AppendLine("VRSTE USLUGA I PROSJEČNE CIJENE:");
        var serviceTypes = await _db.ServiceTypes.ToListAsync();
        if (serviceTypes.Count == 0)
        {
            sb.AppendLine("- Nema podataka o uslugama.");
        }
        else
        {
            foreach (var st in serviceTypes)
            {
                var match = serviceOrders.FirstOrDefault(o => o.Name == st.Name);
                if (match != null)
                {
                    sb.AppendLine($"- {st.Name}: prosječna cijena {match.AvgPrice.ToString("0.00", culture)} KM");
                }
                else
                {
                    sb.AppendLine($"- {st.Name}: cijena na upit");
                }
            }
        }
        sb.AppendLine();

        var myDeceased = await _db.Deceased
            .Include(d => d.ProcedureStatus)
            .Where(d => d.UserId == userId)
            .OrderByDescending(d => d.CreatedAt)
            .ToListAsync();

        sb.AppendLine("MOJE AKTIVNE PROCEDURE:");
        if (myDeceased.Count == 0)
        {
            sb.AppendLine("- Nemate aktivnih procedura.");
        }
        else
        {
            foreach (var d in myDeceased)
            {
                sb.AppendLine($"- {d.FirstName} {d.LastName}, datum smrti: {d.DateOfDeath.ToString("dd.MM.yyyy", culture)}, trenutni status: {d.ProcedureStatus.Name}");
            }
        }
        sb.AppendLine();

        var now = DateTime.UtcNow;
        var sevenDays = now.AddDays(7);

        var apptQuery = _db.Appointments
            .Include(a => a.Deceased)
            .Include(a => a.Mosque).ThenInclude(m => m.City)
            .Include(a => a.Cemetery)
            .Where(a => a.FuneralDateTime >= now && a.FuneralDateTime <= sevenDays && a.Status == "Scheduled");

        if (user.CityId.HasValue)
            apptQuery = apptQuery.Where(a => a.Mosque.CityId == user.CityId.Value);

        var appointments = await apptQuery
            .OrderBy(a => a.FuneralDateTime)
            .Take(20)
            .ToListAsync();

        sb.AppendLine("PREDSTOJEĆI TERMINI (sljedećih 7 dana):");
        if (appointments.Count == 0)
        {
            sb.AppendLine("- Nema zakazanih termina u sljedećih 7 dana.");
        }
        else
        {
            foreach (var a in appointments)
            {
                sb.AppendLine($"- {a.FuneralDateTime.ToString("dd.MM.yyyy HH:mm", culture)} – {a.Deceased.FirstName} {a.Deceased.LastName}, džamija {a.Mosque.Name}, groblje {a.Cemetery.Name}");
            }
        }

        return sb.ToString();
    }
}

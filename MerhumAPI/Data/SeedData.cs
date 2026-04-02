using MerhumAPI.Models;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;

namespace MerhumAPI.Data;

public static class SeedData
{
	public static async Task SeedAsync(IServiceProvider serviceProvider)
	{
		using var scope = serviceProvider.CreateScope();
		var db = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
		var userManager = scope.ServiceProvider.GetRequiredService<UserManager<ApplicationUser>>();
		var roleManager = scope.ServiceProvider.GetRequiredService<RoleManager<IdentityRole>>();

		await db.Database.MigrateAsync();

		if (await db.Countries.AnyAsync())
			return;

		var roles = new[] { "Administrator", "Porodica", "JavniKorisnik", "Imam", "PogrebnoPreduzeće" };
		foreach (var role in roles)
		{
			if (!await roleManager.RoleExistsAsync(role))
				await roleManager.CreateAsync(new IdentityRole(role));
		}

		var bih = new Country { Name = "Bosnia and Herzegovina", Code = "BA" };
		var hrv = new Country { Name = "Croatia", Code = "HR" };
		var srb = new Country { Name = "Serbia", Code = "RS" };
		db.Countries.AddRange(bih, hrv, srb);
		await db.SaveChangesAsync();

		var sarajevo = new City { Name = "Sarajevo", PostalCode = "71000", CountryId = bih.Id };
		var mostar = new City { Name = "Mostar", PostalCode = "88000", CountryId = bih.Id };
		var tuzla = new City { Name = "Tuzla", PostalCode = "75000", CountryId = bih.Id };
		var zenica = new City { Name = "Zenica", PostalCode = "72000", CountryId = bih.Id };
		var banjaLuka = new City { Name = "Banja Luka", PostalCode = "78000", CountryId = bih.Id };
		var bihac = new City { Name = "Bihać", PostalCode = "77000", CountryId = bih.Id };
		var gorazde = new City { Name = "Goražde", PostalCode = "73000", CountryId = bih.Id };
		var trebinje = new City { Name = "Trebinje", PostalCode = "89101", CountryId = bih.Id };
		db.Cities.AddRange(sarajevo, mostar, tuzla, zenica, banjaLuka, bihac, gorazde, trebinje);
		await db.SaveChangesAsync();

		var serviceTypes = new[]
		{
			new ServiceType { Name = "Gasul", Description = "Ritual washing of the deceased" },
			new ServiceType { Name = "Ćefini", Description = "Funeral shroud preparation" },
			new ServiceType { Name = "Tabut", Description = "Funeral casket/bier" },
			new ServiceType { Name = "Transport", Description = "Transport of the deceased" },
			new ServiceType { Name = "Burial", Description = "Grave digging and burial" },
			new ServiceType { Name = "Grave Cleaning", Description = "Cleaning and maintenance of the grave site" }
		};
		db.ServiceTypes.AddRange(serviceTypes);
		await db.SaveChangesAsync();

		var statuses = new[]
		{
			new ProcedureStatus { Name = "Registered", Description = "Initial registration of the deceased", SortOrder = 1 },
			new ProcedureStatus { Name = "DocumentationConfirmed", Description = "All documents have been confirmed", SortOrder = 2 },
			new ProcedureStatus { Name = "AppointmentScheduled", Description = "Funeral appointment has been scheduled", SortOrder = 3 },
			new ProcedureStatus { Name = "ServicesOrdered", Description = "All necessary services have been ordered", SortOrder = 4 },
			new ProcedureStatus { Name = "FuneralPrayerCompleted", Description = "Funeral prayer (Dzenaza) has been performed", SortOrder = 5 },
			new ProcedureStatus { Name = "BurialCompleted", Description = "Burial has been completed", SortOrder = 6 },
			new ProcedureStatus { Name = "Closed", Description = "Procedure fully completed", SortOrder = 7 }
		};
		db.ProcedureStatuses.AddRange(statuses);
		await db.SaveChangesAsync();

		var mosque1 = new Mosque { Name = "Gazi Husrev-beg Mosque", Address = "Bravadžiluk 8", CityId = sarajevo.Id, Phone = "+38733533463", Email = "info@ghb.ba", Capacity = 800, Latitude = 43.8601760m, Longitude = 18.4308060m };
		var mosque2 = new Mosque { Name = "Karadzozbegova Mosque", Address = "Karadžoz-begova bb", CityId = mostar.Id, Phone = "+38736550390", Email = "dzamija@mostar.ba", Capacity = 500, Latitude = 43.3380700m, Longitude = 17.8106400m };
		var mosque3 = new Mosque { Name = "Atik Mosque Tuzla", Address = "Tuzlanska Atik džamija", CityId = tuzla.Id, Phone = "+38735250111", Email = "info@atik-tuzla.ba", Capacity = 400, Latitude = 44.5384020m, Longitude = 18.6726800m };
		var mosque4 = new Mosque { Name = "Ferhadija Mosque", Address = "Ferhadija bb", CityId = banjaLuka.Id, Phone = "+38751211688", Email = "ferhadija@bl.ba", Capacity = 600, Latitude = 44.7729590m, Longitude = 17.1843870m };
		var mosque5 = new Mosque { Name = "Aladza Mosque", Address = "Foča 1", CityId = gorazde.Id, Phone = "+38738221100", Email = "info@aladza.ba", Capacity = 300, Latitude = 43.6679800m, Longitude = 18.9760100m };
		db.Mosques.AddRange(mosque1, mosque2, mosque3, mosque4, mosque5);
		await db.SaveChangesAsync();

		var imam1 = new Imam { FirstName = "Ahmed", LastName = "Mehmedović", MosqueId = mosque1.Id, Phone = "+38761111001", Email = "ahmed.mehmedovic@ghb.ba" };
		var imam2 = new Imam { FirstName = "Ibrahim", LastName = "Hadžić", MosqueId = mosque2.Id, Phone = "+38761111002", Email = "ibrahim.hadzic@mostar.ba" };
		var imam3 = new Imam { FirstName = "Mustafa", LastName = "Begović", MosqueId = mosque3.Id, Phone = "+38761111003", Email = "mustafa.begovic@tuzla.ba" };
		var imam4 = new Imam { FirstName = "Hasan", LastName = "Karić", MosqueId = mosque4.Id, Phone = "+38761111004", Email = "hasan.karic@bl.ba" };
		var imam5 = new Imam { FirstName = "Sulejman", LastName = "Omerović", MosqueId = mosque5.Id, Phone = "+38761111005", Email = "sulejman.omerovic@gorazde.ba" };
		db.Imams.AddRange(imam1, imam2, imam3, imam4, imam5);
		await db.SaveChangesAsync();

		var cem1 = new Cemetery { Name = "Bare Cemetery", Address = "Bare bb, Sarajevo", CityId = sarajevo.Id, TotalPlaces = 5000, Latitude = 43.8452600m, Longitude = 18.3769400m };
		var cem2 = new Cemetery { Name = "Sutina Cemetery", Address = "Sutina bb, Mostar", CityId = mostar.Id, TotalPlaces = 3000, Latitude = 43.3465200m, Longitude = 17.8033900m };
		var cem3 = new Cemetery { Name = "Krušćica Cemetery", Address = "Krušćica bb, Tuzla", CityId = tuzla.Id, TotalPlaces = 2500, Latitude = 44.5312400m, Longitude = 18.6901200m };
		var cem4 = new Cemetery { Name = "Svrakino Cemetery", Address = "Svrakino Selo bb, Zenica", CityId = zenica.Id, TotalPlaces = 2000, Latitude = 44.2037700m, Longitude = 17.9077500m };
		db.Cemeteries.AddRange(cem1, cem2, cem3, cem4);
		await db.SaveChangesAsync();

		var sec1A = new CemeterySection { Name = "Section A", CemeteryId = cem1.Id };
		var sec1B = new CemeterySection { Name = "Section B", CemeteryId = cem1.Id };
		var sec2A = new CemeterySection { Name = "Section A", CemeteryId = cem2.Id };
		var sec2B = new CemeterySection { Name = "Section B", CemeteryId = cem2.Id };
		db.CemeterySections.AddRange(sec1A, sec1B, sec2A, sec2B);
		await db.SaveChangesAsync();

		var graveSites = new List<GraveSite>();
		for (int i = 1; i <= 15; i++)
		{
			graveSites.Add(new GraveSite
			{
				CemeteryId = cem1.Id,
				SectionId = i <= 8 ? sec1A.Id : sec1B.Id,
				PlotNumber = $"A-{i:D3}",
				Row = (i - 1) / 5 + 1,
				Status = i <= 5 ? "Occupied" : i <= 8 ? "Reserved" : "Available"
			});
		}
		for (int i = 1; i <= 15; i++)
		{
			graveSites.Add(new GraveSite
			{
				CemeteryId = cem2.Id,
				SectionId = i <= 8 ? sec2A.Id : sec2B.Id,
				PlotNumber = $"B-{i:D3}",
				Row = (i - 1) / 5 + 1,
				Status = i <= 4 ? "Occupied" : "Available"
			});
		}
		db.GraveSites.AddRange(graveSites);
		await db.SaveChangesAsync();

		var fh1 = new FuneralHome { Name = "Pogrebno Sarajevo", Address = "Čobanija 10, Sarajevo", CityId = sarajevo.Id, Phone = "+38733448888", Email = "info@pogrebno-sa.ba", LicenseNumber = "FH-SA-001" };
		var fh2 = new FuneralHome { Name = "Pokop Mostar", Address = "Bulevar bb, Mostar", CityId = mostar.Id, Phone = "+38736330220", Email = "pokop@mostar.ba", LicenseNumber = "FH-MO-001" };
		var fh3 = new FuneralHome { Name = "Ukop Tuzla", Address = "Solni trg 5, Tuzla", CityId = tuzla.Id, Phone = "+38735271100", Email = "ukop@tuzla.ba", LicenseNumber = "FH-TZ-001" };
		var fh4 = new FuneralHome { Name = "Dzemat Zenica", Address = "Kamberovića čikma 3, Zenica", CityId = zenica.Id, Phone = "+38732419900", Email = "info@dzemat-zenica.ba", LicenseNumber = "FH-ZE-001" };
		db.FuneralHomes.AddRange(fh1, fh2, fh3, fh4);
		await db.SaveChangesAsync();

		var userDefs = new[]
		{
			(Username: "desktop", FullName: "Admin Korisnik", Email: "desktop@merhum.ba", Password: "test", Role: "Administrator"),
			(Username: "mobile", FullName: "Porodica Korisnik", Email: "mobile@merhum.ba", Password: "test", Role: "Porodica"),
			(Username: "korisnik", FullName: "Javni Korisnik", Email: "korisnik@merhum.ba", Password: "test", Role: "JavniKorisnik"),
			(Username: "imam", FullName: "Imam Korisnik", Email: "imam@merhum.ba", Password: "test", Role: "Imam"),
			(Username: "pogrebnopreduzece", FullName: "Pogrebno Preduzece", Email: "pogrebno@merhum.ba", Password: "test", Role: "PogrebnoPreduzeće")
		};

		var createdUsers = new Dictionary<string, ApplicationUser>();
		foreach (var u in userDefs)
		{
			var user = new ApplicationUser
			{
				UserName = u.Username,
				Email = u.Email,
				FullName = u.FullName,
				EmailConfirmed = true
			};
			var result = await userManager.CreateAsync(user, u.Password);
			if (result.Succeeded)
			{
				await userManager.AddToRoleAsync(user, u.Role);
				createdUsers[u.Username] = user;
			}
		}

		var adminUser = createdUsers["desktop"];

		var dec1 = new Deceased { FirstName = "Husein", LastName = "Mehmedović", DateOfBirth = new DateOnly(1940, 3, 15), DateOfDeath = new DateOnly(2024, 1, 10), PlaceOfDeath = "Sarajevo", ContactPersonName = "Adnan Mehmedović", ContactPersonPhone = "+38761200001", ContactPersonEmail = "adnan@example.com", CityId = sarajevo.Id, ProcedureStatusId = statuses[6].Id, UserId = adminUser.Id };
		var dec2 = new Deceased { FirstName = "Fatima", LastName = "Hadžić", DateOfBirth = new DateOnly(1952, 7, 22), DateOfDeath = new DateOnly(2024, 2, 5), PlaceOfDeath = "Mostar", ContactPersonName = "Emir Hadžić", ContactPersonPhone = "+38761200002", ContactPersonEmail = "emir@example.com", CityId = mostar.Id, ProcedureStatusId = statuses[4].Id, UserId = adminUser.Id };
		var dec3 = new Deceased { FirstName = "Mujo", LastName = "Begović", DateOfBirth = new DateOnly(1935, 11, 8), DateOfDeath = new DateOnly(2024, 3, 1), PlaceOfDeath = "Tuzla", ContactPersonName = "Senad Begović", ContactPersonPhone = "+38761200003", CityId = tuzla.Id, ProcedureStatusId = statuses[2].Id, UserId = adminUser.Id };
		var dec4 = new Deceased { FirstName = "Amra", LastName = "Karić", DateOfBirth = new DateOnly(1965, 5, 30), DateOfDeath = new DateOnly(2024, 3, 20), PlaceOfDeath = "Zenica", ContactPersonName = "Nermin Karić", ContactPersonPhone = "+38761200004", CityId = zenica.Id, ProcedureStatusId = statuses[1].Id, UserId = adminUser.Id };
		var dec5 = new Deceased { FirstName = "Salih", LastName = "Omerović", DateOfBirth = new DateOnly(1948, 9, 14), DateOfDeath = new DateOnly(2024, 3, 28), PlaceOfDeath = "Sarajevo", ContactPersonName = "Mirza Omerović", ContactPersonPhone = "+38761200005", CityId = sarajevo.Id, ProcedureStatusId = statuses[0].Id, UserId = adminUser.Id };
		db.Deceased.AddRange(dec1, dec2, dec3, dec4, dec5);
		await db.SaveChangesAsync();

		graveSites[0].DeceasedId = dec1.Id;
		graveSites[1].DeceasedId = dec2.Id;
		graveSites[15].DeceasedId = dec3.Id;
		graveSites[16].DeceasedId = dec4.Id;
		await db.SaveChangesAsync();

		var obit1 = new Obituary { DeceasedId = dec1.Id, UniqueSlug = "husein-mehmedovic-2024-01-10-ab1c2d3e", CreatedByUserId = adminUser.Id };
		var obit2 = new Obituary { DeceasedId = dec2.Id, UniqueSlug = "fatima-hadzic-2024-02-05-cd3e4f5g", CreatedByUserId = adminUser.Id };
		var obit3 = new Obituary { DeceasedId = dec3.Id, UniqueSlug = "mujo-begovic-2024-03-01-ef5g6h7i", CreatedByUserId = adminUser.Id };
		var obit4 = new Obituary { DeceasedId = dec4.Id, UniqueSlug = "amra-karic-2024-03-20-gh7i8j9k", IsPublic = false, CreatedByUserId = adminUser.Id };
		var obit5 = new Obituary { DeceasedId = dec5.Id, UniqueSlug = "salih-omerovic-2024-03-28-ij9k0l1m", CreatedByUserId = adminUser.Id };
		db.Obituaries.AddRange(obit1, obit2, obit3, obit4, obit5);
		await db.SaveChangesAsync();

		db.Condolences.AddRange(
			new Condolence { ObituaryId = obit1.Id, AuthorName = "Amir Begić", Text = "Allah rahmet etsin. Porodici upućujem najdublje saučešće.", IsApproved = true },
			new Condolence { ObituaryId = obit1.Id, AuthorName = "Selma Hodžić", Text = "Neka mu je vječni rahmet.", IsApproved = true },
			new Condolence { ObituaryId = obit1.Id, AuthorName = "Tarik Avdić", Text = "Saučešće porodici.", IsApproved = false },
			new Condolence { ObituaryId = obit2.Id, AuthorName = "Maja Kovačević", Text = "Neka je Allah zadovoljan njome.", IsApproved = true },
			new Condolence { ObituaryId = obit2.Id, AuthorName = "Nedim Čaušević", Text = "Rahmetullahi alejha.", IsApproved = false },
			new Condolence { ObituaryId = obit3.Id, AuthorName = "Irfan Salihović", Text = "Porodici upućujem iskreno saučešće.", IsApproved = true },
			new Condolence { ObituaryId = obit3.Id, AuthorName = "Belma Zukić", Text = "Neka mu Allah podari Džennet.", IsApproved = true },
			new Condolence { ObituaryId = obit4.Id, AuthorName = "Haris Muratović", Text = "Saučešće.", IsApproved = false },
			new Condolence { ObituaryId = obit5.Id, AuthorName = "Elma Čolić", Text = "Neka ga Allah nagradi Džennetom.", IsApproved = true },
			new Condolence { ObituaryId = obit5.Id, AuthorName = "Jasmina Pašić", Text = "Rahmet mu duši.", IsApproved = false }
		);
		await db.SaveChangesAsync();

		var availableGrave = graveSites.First(g => g.Status == "Available" && g.CemeteryId == cem1.Id);

		db.Appointments.AddRange(
			new Appointment { DeceasedId = dec1.Id, MosqueId = mosque1.Id, CemeteryId = cem1.Id, ImamId = imam1.Id, GraveSiteId = graveSites[0].Id, FuneralDateTime = new DateTime(2024, 1, 11, 13, 0, 0), Status = "Held", CreatedByUserId = adminUser.Id },
			new Appointment { DeceasedId = dec2.Id, MosqueId = mosque2.Id, CemeteryId = cem2.Id, ImamId = imam2.Id, GraveSiteId = graveSites[15].Id, FuneralDateTime = new DateTime(2024, 2, 6, 14, 0, 0), Status = "Held", CreatedByUserId = adminUser.Id },
			new Appointment { DeceasedId = dec3.Id, MosqueId = mosque3.Id, CemeteryId = cem3.Id, ImamId = imam3.Id, FuneralDateTime = new DateTime(2024, 3, 2, 13, 30, 0), Status = "Scheduled", CreatedByUserId = adminUser.Id },
			new Appointment { DeceasedId = dec4.Id, MosqueId = mosque4.Id, CemeteryId = cem4.Id, FuneralDateTime = new DateTime(2024, 3, 21, 15, 0, 0), Status = "Scheduled", CreatedByUserId = adminUser.Id },
			new Appointment { DeceasedId = dec5.Id, MosqueId = mosque1.Id, CemeteryId = cem1.Id, FuneralDateTime = new DateTime(2024, 3, 29, 13, 0, 0), Status = "Scheduled", CreatedByUserId = adminUser.Id }
		);
		await db.SaveChangesAsync();

		db.ServiceOrders.AddRange(
			new ServiceOrder { DeceasedId = dec1.Id, FuneralHomeId = fh1.Id, ServiceTypeId = serviceTypes[0].Id, Price = 150.00m, Status = "Completed", CompletedAt = new DateTime(2024, 1, 11, 10, 0, 0) },
			new ServiceOrder { DeceasedId = dec1.Id, FuneralHomeId = fh1.Id, ServiceTypeId = serviceTypes[2].Id, Price = 300.00m, Status = "Completed", CompletedAt = new DateTime(2024, 1, 11, 11, 0, 0) },
			new ServiceOrder { DeceasedId = dec2.Id, FuneralHomeId = fh2.Id, ServiceTypeId = serviceTypes[0].Id, Price = 150.00m, Status = "Completed" },
			new ServiceOrder { DeceasedId = dec2.Id, FuneralHomeId = fh2.Id, ServiceTypeId = serviceTypes[3].Id, Price = 200.00m, Status = "Completed" },
			new ServiceOrder { DeceasedId = dec3.Id, FuneralHomeId = fh3.Id, ServiceTypeId = serviceTypes[0].Id, Price = 150.00m, Status = "InProgress" },
			new ServiceOrder { DeceasedId = dec3.Id, FuneralHomeId = fh3.Id, ServiceTypeId = serviceTypes[1].Id, Price = 80.00m, Status = "Ordered" },
			new ServiceOrder { DeceasedId = dec4.Id, FuneralHomeId = fh4.Id, ServiceTypeId = serviceTypes[0].Id, Price = 150.00m, Status = "Ordered" },
			new ServiceOrder { DeceasedId = dec5.Id, FuneralHomeId = fh1.Id, ServiceTypeId = serviceTypes[0].Id, Price = 150.00m, Status = "Ordered" }
		);
		await db.SaveChangesAsync();
	}
}

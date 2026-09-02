using MerhumAPI.Common;
using MerhumAPI.Data;
using MerhumAPI.DTOs.ReferenceData;
using MerhumAPI.Models;
using Microsoft.EntityFrameworkCore;

namespace MerhumAPI.Services;

public class ReferenceDataService : IReferenceDataService
{
    private readonly ApplicationDbContext _db;
    public ReferenceDataService(ApplicationDbContext db) => _db = db;

    public async Task<PagedResponse<CountryResponse>> GetCountriesAsync(int pageNumber, int pageSize)
    {
        (pageNumber, pageSize) = Pagination.Normalize(pageNumber, pageSize);

        var query = _db.Countries.OrderBy(c => c.Name);
        var total = await query.CountAsync();
        var items = await query
            .Skip((pageNumber - 1) * pageSize)
            .Take(pageSize)
            .Select(c => new CountryResponse { Id = c.Id, Name = c.Name, Code = c.Code })
            .ToListAsync();

        return PagedResponse<CountryResponse>.Create(items, total, pageNumber, pageSize);
    }

    public async Task<CountryResponse> CreateCountryAsync(CountryRequest request)
    {
        var country = new Country { Name = request.Name, Code = request.Code.ToUpper() };
        _db.Countries.Add(country);
        await _db.SaveChangesAsync();
        return new CountryResponse { Id = country.Id, Name = country.Name, Code = country.Code };
    }

    public async Task<bool> UpdateCountryAsync(int id, CountryRequest request)
    {
        var country = await _db.Countries.FindAsync(id);
        if (country == null) return false;
        country.Name = request.Name;
        country.Code = request.Code.ToUpper();
        await _db.SaveChangesAsync();
        return true;
    }

    public async Task<bool> DeleteCountryAsync(int id)
    {
        var country = await _db.Countries.FindAsync(id);
        if (country == null) return false;
        _db.Countries.Remove(country);
        await _db.SaveChangesAsync();
        return true;
    }

    public async Task<PagedResponse<CityResponse>> GetCitiesAsync(int? countryId, int pageNumber, int pageSize)
    {
        (pageNumber, pageSize) = Pagination.Normalize(pageNumber, pageSize);

        var query = _db.Cities.Include(c => c.Country).AsQueryable();
        if (countryId.HasValue)
            query = query.Where(c => c.CountryId == countryId.Value);

        query = query.OrderBy(c => c.Name);
        var total = await query.CountAsync();
        var items = await query
            .Skip((pageNumber - 1) * pageSize)
            .Take(pageSize)
            .Select(c => new CityResponse { Id = c.Id, Name = c.Name, PostalCode = c.PostalCode, CountryId = c.CountryId, CountryName = c.Country.Name })
            .ToListAsync();

        return PagedResponse<CityResponse>.Create(items, total, pageNumber, pageSize);
    }

    public async Task<CityResponse?> CreateCityAsync(CityRequest request)
    {
        var city = new City { Name = request.Name, PostalCode = request.PostalCode, CountryId = request.CountryId };
        _db.Cities.Add(city);
        await _db.SaveChangesAsync();

        var country = await _db.Countries.FindAsync(request.CountryId);
        return new CityResponse { Id = city.Id, Name = city.Name, PostalCode = city.PostalCode, CountryId = city.CountryId, CountryName = country?.Name ?? "" };
    }

    public async Task<bool> UpdateCityAsync(int id, CityRequest request)
    {
        var city = await _db.Cities.FindAsync(id);
        if (city == null) return false;
        city.Name = request.Name;
        city.PostalCode = request.PostalCode;
        city.CountryId = request.CountryId;
        await _db.SaveChangesAsync();
        return true;
    }

    public async Task<bool> DeleteCityAsync(int id)
    {
        var city = await _db.Cities.FindAsync(id);
        if (city == null) return false;
        _db.Cities.Remove(city);
        await _db.SaveChangesAsync();
        return true;
    }

    public async Task<PagedResponse<ServiceTypeResponse>> GetServiceTypesAsync(int pageNumber, int pageSize)
    {
        (pageNumber, pageSize) = Pagination.Normalize(pageNumber, pageSize);

        var query = _db.ServiceTypes.OrderBy(s => s.Name);
        var total = await query.CountAsync();
        var items = await query
            .Skip((pageNumber - 1) * pageSize)
            .Take(pageSize)
            .Select(s => new ServiceTypeResponse { Id = s.Id, Name = s.Name, Description = s.Description })
            .ToListAsync();

        return PagedResponse<ServiceTypeResponse>.Create(items, total, pageNumber, pageSize);
    }

    public async Task<ServiceTypeResponse> CreateServiceTypeAsync(ServiceTypeRequest request)
    {
        var st = new ServiceType { Name = request.Name, Description = request.Description };
        _db.ServiceTypes.Add(st);
        await _db.SaveChangesAsync();
        return new ServiceTypeResponse { Id = st.Id, Name = st.Name, Description = st.Description };
    }

    public async Task<bool> UpdateServiceTypeAsync(int id, ServiceTypeRequest request)
    {
        var st = await _db.ServiceTypes.FindAsync(id);
        if (st == null) return false;
        st.Name = request.Name;
        st.Description = request.Description;
        await _db.SaveChangesAsync();
        return true;
    }

    public async Task<bool> DeleteServiceTypeAsync(int id)
    {
        var st = await _db.ServiceTypes.FindAsync(id);
        if (st == null) return false;
        _db.ServiceTypes.Remove(st);
        await _db.SaveChangesAsync();
        return true;
    }

    public async Task<PagedResponse<ProcedureStatusResponse>> GetProcedureStatusesAsync(int pageNumber, int pageSize)
    {
        (pageNumber, pageSize) = Pagination.Normalize(pageNumber, pageSize);

        var query = _db.ProcedureStatuses.OrderBy(s => s.SortOrder);
        var total = await query.CountAsync();
        var items = await query
            .Skip((pageNumber - 1) * pageSize)
            .Take(pageSize)
            .Select(s => new ProcedureStatusResponse { Id = s.Id, Name = s.Name, Description = s.Description, SortOrder = s.SortOrder })
            .ToListAsync();

        return PagedResponse<ProcedureStatusResponse>.Create(items, total, pageNumber, pageSize);
    }

    public async Task<PagedResponse<CemeterySectionResponse>> GetCemeterySectionsAsync(int? cemeteryId, int pageNumber, int pageSize)
    {
        (pageNumber, pageSize) = Pagination.Normalize(pageNumber, pageSize);

        var query = _db.CemeterySections.AsQueryable();
        if (cemeteryId.HasValue)
            query = query.Where(s => s.CemeteryId == cemeteryId.Value);

        query = query.OrderBy(s => s.Name);
        var total = await query.CountAsync();
        var items = await query
            .Skip((pageNumber - 1) * pageSize)
            .Take(pageSize)
            .Select(s => new CemeterySectionResponse { Id = s.Id, Name = s.Name, CemeteryId = s.CemeteryId })
            .ToListAsync();

        return PagedResponse<CemeterySectionResponse>.Create(items, total, pageNumber, pageSize);
    }

    public async Task<CemeterySectionResponse> CreateSectionAsync(SectionRequest request)
    {
        var section = new CemeterySection { Name = request.Name, CemeteryId = request.CemeteryId };
        _db.CemeterySections.Add(section);
        await _db.SaveChangesAsync();
        return new CemeterySectionResponse { Id = section.Id, Name = section.Name, CemeteryId = section.CemeteryId };
    }

    public async Task<bool> UpdateSectionAsync(int id, SectionRequest request)
    {
        var section = await _db.CemeterySections.FindAsync(id);
        if (section == null) return false;
        section.Name = request.Name;
        section.CemeteryId = request.CemeteryId;
        await _db.SaveChangesAsync();
        return true;
    }

    public async Task<bool> DeleteSectionAsync(int id)
    {
        var section = await _db.CemeterySections.FindAsync(id);
        if (section == null) return false;
        _db.CemeterySections.Remove(section);
        await _db.SaveChangesAsync();
        return true;
    }
}

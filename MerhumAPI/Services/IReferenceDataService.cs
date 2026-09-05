using MerhumAPI.Common;
using MerhumAPI.DTOs.ReferenceData;

namespace MerhumAPI.Services;

public interface IReferenceDataService
{
    Task<PagedResponse<CountryResponse>> GetCountriesAsync(int pageNumber, int pageSize);
    Task<CountryResponse> CreateCountryAsync(CountryRequest request);
    Task<bool> UpdateCountryAsync(int id, CountryRequest request);
    Task<bool> DeleteCountryAsync(int id);

    Task<PagedResponse<CityResponse>> GetCitiesAsync(int? countryId, int pageNumber, int pageSize);
    Task<CityResponse?> CreateCityAsync(CityRequest request);
    Task<bool> UpdateCityAsync(int id, CityRequest request);
    Task<bool> DeleteCityAsync(int id);

    Task<PagedResponse<ServiceTypeResponse>> GetServiceTypesAsync(int pageNumber, int pageSize);
    Task<ServiceTypeResponse> CreateServiceTypeAsync(ServiceTypeRequest request);
    Task<bool> UpdateServiceTypeAsync(int id, ServiceTypeRequest request);
    Task<bool> DeleteServiceTypeAsync(int id);

    Task<PagedResponse<ProcedureStatusResponse>> GetProcedureStatusesAsync(int pageNumber, int pageSize);

    Task<PagedResponse<MuftiateResponse>> GetMuftiatesAsync(int pageNumber, int pageSize);
    Task<PagedResponse<MajlisResponse>> GetMajlisesAsync(int? muftiateId, int pageNumber, int pageSize);

    Task<PagedResponse<CemeterySectionResponse>> GetCemeterySectionsAsync(int? cemeteryId, int pageNumber, int pageSize);
    Task<CemeterySectionResponse> CreateSectionAsync(SectionRequest request);
    Task<bool> UpdateSectionAsync(int id, SectionRequest request);
    Task<bool> DeleteSectionAsync(int id);
}

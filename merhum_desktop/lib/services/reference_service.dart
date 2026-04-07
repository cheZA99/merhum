import '../models/reference/cemetery_sector_model.dart';
import '../models/reference/city_model.dart';
import '../models/reference/country_model.dart';
import '../models/reference/service_type_model.dart';
import 'api_service.dart';

class ReferenceService {
  final ApiService _api;
  ReferenceService(this._api);

  // Countries

  Future<List<CountryModel>> getCountries() async {
    final response = await _api.get('/api/referencedata/countries');
    final raw = response.data;
    final list = raw is List ? raw : (raw['data'] as List? ?? []);
    return list
        .map((e) => CountryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> createCountry(Map<String, dynamic> data) async {
    await _api.post('/api/referencedata/countries', data: data);
  }

  Future<void> updateCountry(int id, Map<String, dynamic> data) async {
    await _api.put('/api/referencedata/countries/$id', data: data);
  }

  Future<void> deleteCountry(int id) async {
    await _api.delete('/api/referencedata/countries/$id');
  }

  // Cities

  Future<List<CityModel>> getCities({int? countryId}) async {
    final params = <String, dynamic>{};
    if (countryId != null) params['countryId'] = countryId;

    final response =
        await _api.get('/api/referencedata/cities', queryParams: params);
    final raw = response.data;
    final list = raw is List ? raw : (raw['data'] as List? ?? []);
    return list
        .map((e) => CityModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> createCity(Map<String, dynamic> data) async {
    await _api.post('/api/referencedata/cities', data: data);
  }

  Future<void> updateCity(int id, Map<String, dynamic> data) async {
    await _api.put('/api/referencedata/cities/$id', data: data);
  }

  Future<void> deleteCity(int id) async {
    await _api.delete('/api/referencedata/cities/$id');
  }

  // Service types

  Future<List<ServiceTypeModel>> getServiceTypes() async {
    final response = await _api.get('/api/referencedata/service-types');
    final raw = response.data;
    final list = raw is List ? raw : (raw['data'] as List? ?? []);
    return list
        .map((e) => ServiceTypeModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> createServiceType(Map<String, dynamic> data) async {
    await _api.post('/api/referencedata/service-types', data: data);
  }

  Future<void> updateServiceType(int id, Map<String, dynamic> data) async {
    await _api.put('/api/referencedata/service-types/$id', data: data);
  }

  Future<void> deleteServiceType(int id) async {
    await _api.delete('/api/referencedata/service-types/$id');
  }

  // Cemetery sections

  Future<List<CemeterySectorModel>> getSectors({int? cemeteryId}) async {
    final params = <String, dynamic>{};
    if (cemeteryId != null) params['cemeteryId'] = cemeteryId;

    final response = await _api.get('/api/referencedata/cemetery-sections',
        queryParams: params);
    final raw = response.data;
    final list = raw is List ? raw : (raw['data'] as List? ?? []);
    return list
        .map((e) => CemeterySectorModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> createSector(Map<String, dynamic> data) async {
    await _api.post('/api/referencedata/cemetery-sections', data: data);
  }

  Future<void> updateSector(int id, Map<String, dynamic> data) async {
    await _api.put('/api/referencedata/cemetery-sections/$id', data: data);
  }

  Future<void> deleteSector(int id) async {
    await _api.delete('/api/referencedata/cemetery-sections/$id');
  }

  // Cemeteries for dropdown

  Future<List<Map<String, dynamic>>> getCemeteries() async {
    final response =
        await _api.get('/api/cemetery', queryParams: {'pageSize': 500});
    final raw = response.data as Map<String, dynamic>;
    final list = raw['data'] as List? ?? [];
    return list.cast<Map<String, dynamic>>();
  }
}

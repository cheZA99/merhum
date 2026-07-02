import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../models/reference/cemetery_sector_model.dart';
import '../models/reference/city_model.dart';
import '../models/reference/country_model.dart';
import '../models/reference/service_type_model.dart';
import '../services/reference_service.dart';

class ReferenceProvider extends ChangeNotifier {
  final ReferenceService _service;
  ReferenceProvider(this._service);

  List<CountryModel> countries = [];
  List<CityModel> cities = [];
  List<ServiceTypeModel> serviceTypes = [];
  List<CemeterySectorModel> sectors = [];
  List<Map<String, dynamic>> cemeteries = [];
  bool isLoading = false;
  String? errorMessage;
  int? filterCountryId;
  int? filterCemeteryId;

  Future<void> loadCountries() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      countries = await _service.getCountries();
    } on DioException catch (e) {
      errorMessage = _parseError(e);
    } catch (e) {
      errorMessage = 'Error loading: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadCities({int? countryId}) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      cities = await _service.getCities(countryId: countryId);
    } on DioException catch (e) {
      errorMessage = _parseError(e);
    } catch (e) {
      errorMessage = 'Error loading: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadServiceTypes() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      serviceTypes = await _service.getServiceTypes();
    } on DioException catch (e) {
      errorMessage = _parseError(e);
    } catch (e) {
      errorMessage = 'Error loading: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadSectors({int? cemeteryId}) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final raw = await _service.getSectors(cemeteryId: cemeteryId);
      // backend doesn't send cemeteryName, fill it here
      sectors = raw.map((s) {
        final match = cemeteries.firstWhere(
          (c) => c['id'] == s.cemeteryId,
          orElse: () => <String, dynamic>{},
        );
        return s.copyWith(cemeteryName: match['name'] as String? ?? '');
      }).toList();
    } on DioException catch (e) {
      errorMessage = _parseError(e);
    } catch (e) {
      errorMessage = 'Error loading: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadCemeteries() async {
    try {
      cemeteries = await _service.getCemeteries();
    } catch (_) {}
    notifyListeners();
  }

  Future<bool> createCountry(Map<String, dynamic> data) async {
    try {
      await _service.createCountry(data);
      await loadCountries();
      return true;
    } on DioException catch (e) {
      errorMessage = _parseError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateCountry(int id, Map<String, dynamic> data) async {
    try {
      await _service.updateCountry(id, data);
      await loadCountries();
      return true;
    } on DioException catch (e) {
      errorMessage = _parseError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteCountry(int id) async {
    try {
      await _service.deleteCountry(id);
      countries.removeWhere((c) => c.id == id);
      notifyListeners();
      return true;
    } on DioException catch (e) {
      errorMessage = _parseError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> createCity(Map<String, dynamic> data) async {
    try {
      await _service.createCity(data);
      await loadCities(countryId: filterCountryId);
      return true;
    } on DioException catch (e) {
      errorMessage = _parseError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateCity(int id, Map<String, dynamic> data) async {
    try {
      await _service.updateCity(id, data);
      await loadCities(countryId: filterCountryId);
      return true;
    } on DioException catch (e) {
      errorMessage = _parseError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteCity(int id) async {
    try {
      await _service.deleteCity(id);
      cities.removeWhere((c) => c.id == id);
      notifyListeners();
      return true;
    } on DioException catch (e) {
      errorMessage = _parseError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> createServiceType(Map<String, dynamic> data) async {
    try {
      await _service.createServiceType(data);
      await loadServiceTypes();
      return true;
    } on DioException catch (e) {
      errorMessage = _parseError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateServiceType(int id, Map<String, dynamic> data) async {
    try {
      await _service.updateServiceType(id, data);
      await loadServiceTypes();
      return true;
    } on DioException catch (e) {
      errorMessage = _parseError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteServiceType(int id) async {
    try {
      await _service.deleteServiceType(id);
      serviceTypes.removeWhere((s) => s.id == id);
      notifyListeners();
      return true;
    } on DioException catch (e) {
      errorMessage = _parseError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> createSector(Map<String, dynamic> data) async {
    try {
      await _service.createSector(data);
      await loadSectors(cemeteryId: filterCemeteryId);
      return true;
    } on DioException catch (e) {
      errorMessage = _parseError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateSector(int id, Map<String, dynamic> data) async {
    try {
      await _service.updateSector(id, data);
      await loadSectors(cemeteryId: filterCemeteryId);
      return true;
    } on DioException catch (e) {
      errorMessage = _parseError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteSector(int id) async {
    try {
      await _service.deleteSector(id);
      sectors.removeWhere((s) => s.id == id);
      notifyListeners();
      return true;
    } on DioException catch (e) {
      errorMessage = _parseError(e);
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }

  String _parseError(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      return data['message'] as String? ??
          data['title'] as String? ??
          'Server error.';
    }
    if (e.type == DioExceptionType.connectionError) return 'Nema konekcije sa serverom.';
    if (e.response?.statusCode == 401) return 'Sesija je istekla. Prijavite se ponovo.';
    if (e.response?.statusCode == 403) return 'Nemate ovlaštenja za ovu akciju.';
    return 'Neočekivana greška (${e.response?.statusCode}).';
  }
}

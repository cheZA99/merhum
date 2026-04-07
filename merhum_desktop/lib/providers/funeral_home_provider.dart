import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../models/funeral_home_model.dart';
import '../services/funeral_home_service.dart';

class FuneralHomeProvider extends ChangeNotifier {
  final FuneralHomeService _service;
  FuneralHomeProvider(this._service);

  List<FuneralHomeModel> _all = [];
  List<Map<String, dynamic>> cities = [];
  bool isLoading = false;
  String? errorMessage;
  String? searchName;
  int? filterCityId;
  int currentPage = 1;
  int totalPages = 1;
  static const int pageSize = 10;

  // Client-side city filter — API only supports search by name
  List<FuneralHomeModel> get funeralHomes {
    if (filterCityId == null) return _all;
    return _all.where((h) => h.cityId == filterCityId).toList();
  }

  Future<void> loadAll({int page = 1}) async {
    isLoading = true;
    errorMessage = null;
    currentPage = page;
    notifyListeners();

    try {
      final result = await _service.getAll(
        search: searchName,
        pageNumber: page,
        pageSize: pageSize,
      );
      _all = result.$1;
      final total = result.$2;
      totalPages = (total / pageSize).ceil().clamp(1, 99999);
    } on DioException catch (e) {
      errorMessage = _parseError(e);
    } catch (e) {
      errorMessage = 'Error loading: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadCities() async {
    try {
      cities = await _service.getCities();
    } catch (_) {}
    errorMessage = null;
    notifyListeners();
  }

  Future<bool> create(Map<String, dynamic> data) async {
    try {
      await _service.create(data);
      await loadAll(page: 1);
      return true;
    } on DioException catch (e) {
      errorMessage = _parseError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> update(int id, Map<String, dynamic> data) async {
    try {
      await _service.update(id, data);
      await loadAll(page: currentPage);
      return true;
    } on DioException catch (e) {
      errorMessage = _parseError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> delete(int id) async {
    try {
      await _service.delete(id);
      _all.removeWhere((h) => h.id == id);
      notifyListeners();
      return true;
    } on DioException catch (e) {
      errorMessage = _parseError(e);
      notifyListeners();
      return false;
    }
  }

  void setSearch(String name) {
    searchName = name.isEmpty ? null : name;
    loadAll(page: 1);
  }

  void setFilterCity(int? cityId) {
    filterCityId = cityId;
    notifyListeners(); // client-side only, no API call
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
    if (e.type == DioExceptionType.connectionError) return 'No server connection.';
    if (e.response?.statusCode == 404) return 'Funeral home not found.';
    if (e.response?.statusCode == 409) return 'A funeral home with that data already exists.';
    return 'Unexpected error (${e.response?.statusCode}).';
  }
}

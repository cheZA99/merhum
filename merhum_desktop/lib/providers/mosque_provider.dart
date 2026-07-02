import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../models/mosque_model.dart';
import '../services/mosque_service.dart';

class MosqueProvider extends ChangeNotifier {
  final MosqueService _service;

  MosqueProvider(this._service);

  List<MosqueModel> _all = [];
  List<Map<String, dynamic>> cities = [];
  bool isLoading = false;
  String? errorMessage;
  String? searchName;
  int? filterCityId;

  // filter by city locally, API has no cityId param
  List<MosqueModel> get mosques {
    if (filterCityId == null) return _all;
    return _all.where((m) => m.cityId == filterCityId).toList();
  }

  Future<void> loadAll() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      _all = await _service.getAll(search: searchName);
    } on DioException catch (e) {
      errorMessage = _parseError(e);
    } catch (e) {
      errorMessage = 'Error loading.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadCities() async {
    try {
      cities = await _service.getCities();
    } catch (_) {
    }
    notifyListeners();
  }

  Future<bool> create(Map<String, dynamic> data) async {
    try {
      await _service.create(data);
      await loadAll();
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
      await loadAll();
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
      _all.removeWhere((m) => m.id == id);
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
    loadAll();
  }

  void setFilterCity(int? cityId) {
    filterCityId = cityId;
    notifyListeners(); // re-filter only, no API call
  }

  String _parseError(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      return data['message'] as String? ?? data['title'] as String? ?? 'Server error.';
    }
    if (e.type == DioExceptionType.connectionError) return 'No server connection.';
    if (e.response?.statusCode == 404) return 'Mosque not found.';
    if (e.response?.statusCode == 409) return 'A mosque with that name already exists.';
    return 'Unexpected error (${e.response?.statusCode}).';
  }
}

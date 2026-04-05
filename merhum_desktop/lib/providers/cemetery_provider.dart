import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../models/cemetery_model.dart';
import '../services/cemetery_service.dart';

class CemeteryProvider extends ChangeNotifier {
  final CemeteryService _service;
  CemeteryProvider(this._service);

  List<CemeteryModel> _all = [];
  List<Map<String, dynamic>> cities = [];
  bool isLoading = false;
  String? errorMessage;
  String? searchName;
  int? filterCityId;

  List<CemeteryModel> get cemeteries {
    if (filterCityId == null) return _all;
    return _all.where((g) => g.cityId == filterCityId).toList();
  }

  Future<void> loadAll() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      _all = await _service.getAll(name: searchName);
    } on DioException catch (e) {
      errorMessage = _parseError(e);
    } catch (_) {
      errorMessage = 'Error loading cemeteries.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadCities() async {
    try {
      cities = await _service.getCities();
    } catch (_) {}
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
      _all.removeWhere((g) => g.id == id);
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

  void setSearch(String name) {
    searchName = name.isEmpty ? null : name;
    loadAll();
  }

  void setFilterCity(int? cityId) {
    filterCityId = cityId;
    notifyListeners();
  }

  String _parseError(DioException e) {
    final data = e.response?.data;
    if (data is Map) return data['message'] as String? ?? 'Server error.';
    if (e.type == DioExceptionType.connectionError) return 'No server connection.';
    if (e.response?.statusCode == 404) return 'Cemetery not found.';
    return 'Error (${e.response?.statusCode}).';
  }
}

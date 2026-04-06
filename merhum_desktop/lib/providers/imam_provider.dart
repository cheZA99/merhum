import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../models/imam_model.dart';
import '../services/imam_service.dart';

class ImamProvider extends ChangeNotifier {
  final ImamService _service;
  ImamProvider(this._service);

  List<ImamModel> imams = [];
  List<Map<String, dynamic>> mosques = [];
  bool isLoading = false;
  String? errorMessage;
  String? searchName;
  int? filterMosqueId;
  int currentPage = 1;
  int totalPages = 1;
  static const int pageSize = 10;

  Future<void> loadAll({int page = 1}) async {
    isLoading = true;
    errorMessage = null;
    currentPage = page;
    notifyListeners();

    try {
      final result = await _service.getAll(
        mosqueId: filterMosqueId,
        name: searchName,
        pageNumber: page,
        pageSize: pageSize,
      );
      imams = result.$1;
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

  Future<void> loadMosques() async {
    try {
      mosques = await _service.getMosques();
    } catch (_) {}
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
      imams.removeWhere((m) => m.id == id);
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

  void setFilterMosque(int? mosqueId) {
    filterMosqueId = mosqueId;
    loadAll(page: 1);
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
    if (e.response?.statusCode == 404) return 'Imam nije pronađen.';
    if (e.response?.statusCode == 409) return 'Imam sa tim podacima već postoji.';
    return 'Neočekivana greška (${e.response?.statusCode}).';
  }
}

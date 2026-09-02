import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../models/deceased_model.dart';
import '../models/procedure_status_model.dart';
import '../models/status_history_model.dart';
import '../services/deceased_service.dart';

class DeceasedProvider extends ChangeNotifier {
  final DeceasedService _service;
  DeceasedProvider(this._service);

  List<DeceasedModel> deceasedList = [];
  List<ProcedureStatusModel> statuses = [];
  List<Map<String, dynamic>> cities = [];
  bool isLoading = false;
  String? errorMessage;
  int currentPage = 1;
  static const int pageSize = 10;
  String? filterSearch;
  int? filterCityId;
  int? filterStatusId;
  int totalCount = 0;
  int totalDeceasedCount = 0;
  List<DeceasedModel> recentDeceased = [];

  int get totalPages => (totalCount / pageSize).ceil().clamp(1, 99999);

  Future<void> loadAll() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final (list, total) = await _service.getAll(
        search: filterSearch,
        statusId: filterStatusId,
        cityId: filterCityId,
        pageNumber: currentPage,
        pageSize: pageSize,
      );
      deceasedList = list;
      totalCount = total;
    } on DioException catch (e) {
      errorMessage = _parseError(e);
    } catch (e) {
      errorMessage = 'Greška pri učitavanju: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadTotalDeceasedCount() async {
    try {
      final (_, total) = await _service.getAll(pageNumber: 1, pageSize: 1);
      totalDeceasedCount = total;
    } catch (_) {}
    notifyListeners();
  }

  Future<void> loadRecentDeceased() async {
    try {
      final (list, _) = await _service.getAll(pageNumber: 1, pageSize: 5);
      recentDeceased = list;
    } catch (_) {}
    notifyListeners();
  }

  Future<void> loadStatuses() async {
    try {
      statuses = await _service.getStatuses();
    } catch (_) {}
    notifyListeners();
  }

  Future<void> loadCities() async {
    try {
      cities = await _service.getCities();
    } catch (_) {}
    notifyListeners();
  }

  Future<DeceasedModel?> getDetails(int id) async {
    try {
      return await _service.getById(id);
    } on DioException catch (e) {
      errorMessage = _parseError(e);
      notifyListeners();
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<List<StatusHistoryModel>> getHistory(int id) async {
    try {
      return await _service.getStatusHistory(id);
    } catch (_) {
      return [];
    }
  }

  Future<bool> create(Map<String, dynamic> data) async {
    try {
      await _service.create(data);
      currentPage = 1;
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

  Future<bool> updateStatus(int id, int statusId, String? note) async {
    try {
      await _service.updateStatus(id, statusId, note);
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
      if (currentPage > 1 && deceasedList.length == 1) currentPage--;
      await loadAll();
      return true;
    } on DioException catch (e) {
      errorMessage = _parseError(e);
      notifyListeners();
      return false;
    }
  }

  void nextPage() {
    if (currentPage < totalPages) {
      currentPage++;
      loadAll();
    }
  }

  void previousPage() {
    if (currentPage > 1) {
      currentPage--;
      loadAll();
    }
  }

  void setSearch(String v) {
    filterSearch = v.isEmpty ? null : v;
    currentPage = 1;
    loadAll();
  }

  void setFilterCity(int? v) {
    filterCityId = v;
    currentPage = 1;
    loadAll();
  }

  void setFilterStatus(int? v) {
    filterStatusId = v;
    currentPage = 1;
    loadAll();
  }

  void resetFilters() {
    filterSearch = null;
    filterCityId = null;
    filterStatusId = null;
    currentPage = 1;
    loadAll();
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
          'Greška servera.';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'Nema konekcije sa serverom.';
    }
    if (e.response?.statusCode == 401) {
      return 'Sesija je istekla. Prijavite se ponovo.';
    }
    if (e.response?.statusCode == 403) {
      return 'Nemate ovlaštenja za ovu akciju.';
    }
    if (e.response?.statusCode == 404) {
      return 'Zapis nije pronađen.';
    }
    if (e.response?.statusCode == 409) {
      return 'Zapis sa tim podacima već postoji.';
    }
    return 'Neočekivana greška (${e.response?.statusCode}).';
  }
}

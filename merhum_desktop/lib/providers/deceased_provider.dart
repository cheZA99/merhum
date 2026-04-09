import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../models/deceased_model.dart';
import '../models/procedure_status_model.dart';
import '../models/status_history_model.dart';
import '../services/deceased_service.dart';

class DeceasedProvider extends ChangeNotifier {
  final DeceasedService _service;
  DeceasedProvider(this._service);

  List<DeceasedModel> _all = [];
  List<ProcedureStatusModel> statuses = [];
  List<Map<String, dynamic>> cities = [];
  bool isLoading = false;
  String? errorMessage;
  int currentPage = 1;
  static const int pageSize = 10;
  String? filterSearch;
  int? filterCityId;
  int? filterStatusId;

  List<DeceasedModel> get deceasedList {
    final start = (currentPage - 1) * pageSize;
    final end = (start + pageSize).clamp(0, _all.length);
    return _all.sublist(start, end);
  }

  int get totalPages => (_all.length / pageSize).ceil().clamp(1, 99999);
  int get totalCount => _all.length;

  Future<void> loadAll() async {
    isLoading = true;
    errorMessage = null;
    currentPage = 1;
    notifyListeners();

    try {
      _all = await _service.getAll(
        search: filterSearch,
        statusId: filterStatusId,
        cityId: filterCityId,
      );
    } on DioException catch (e) {
      errorMessage = _parseError(e);
    } catch (e) {
      errorMessage = 'Greška pri učitavanju: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
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
      _all.removeWhere((d) => d.id == id);
      notifyListeners();
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
      notifyListeners();
    }
  }

  void previousPage() {
    if (currentPage > 1) {
      currentPage--;
      notifyListeners();
    }
  }

  void setSearch(String v) {
    filterSearch = v.isEmpty ? null : v;
    loadAll();
  }

  void setFilterCity(int? v) {
    filterCityId = v;
    loadAll();
  }

  void setFilterStatus(int? v) {
    filterStatusId = v;
    loadAll();
  }

  void resetFilters() {
    filterSearch = null;
    filterCityId = null;
    filterStatusId = null;
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

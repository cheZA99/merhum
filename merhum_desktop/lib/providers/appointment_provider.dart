import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../models/appointment_model.dart';
import '../services/appointment_service.dart';

class AppointmentProvider extends ChangeNotifier {
  final AppointmentService _service;
  AppointmentProvider(this._service);

  List<AppointmentModel> appointments = [];
  List<Map<String, dynamic>> mosques = [];
  List<Map<String, dynamic>> cemeteries = [];
  List<Map<String, dynamic>> imams = [];
  List<Map<String, dynamic>> graveSites = [];
  List<Map<String, dynamic>> deceased = [];

  bool isLoading = false;
  String? errorMessage;
  int currentPage = 1;
  int totalCount = 0;
  static const int pageSize = 10;
  int activeCount = 0;
  List<AppointmentModel> upcomingAppointments = [];

  int? filterMosqueId;
  int? filterImamId;
  String? filterStatus;
  DateTime? filterDateFrom;
  DateTime? filterDateTo;
  int? deceasedIdContext;

  int get totalPages => (totalCount / pageSize).ceil().clamp(1, 99999);

  Future<void> loadAll() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final (list, total) = await _service.getAll(
        deceasedId: deceasedIdContext,
        status: filterStatus,
        mosqueId: filterMosqueId,
        imamId: filterImamId,
        dateFrom: filterDateFrom,
        dateTo: filterDateTo,
        pageNumber: currentPage,
        pageSize: pageSize,
      );
      appointments = list;
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

  Future<void> loadActiveCount() async {
    try {
      activeCount = await _service.getActiveCount();
    } catch (_) {}
    notifyListeners();
  }

  Future<void> loadUpcoming() async {
    try {
      final (list, _) = await _service.getAll(
        status: 'Scheduled',
        dateFrom: DateTime.now(),
        pageSize: 20,
      );
      list.sort((a, b) => a.funeralDateTime.compareTo(b.funeralDateTime));
      upcomingAppointments = list.take(5).toList();
    } catch (_) {}
    notifyListeners();
  }

  Future<void> loadDropdownData() async {
    try {
      final results = await Future.wait([
        _service.getMosques(),
        _service.getCemeteries(),
        _service.getDeceased(),
      ]);
      mosques = results[0];
      cemeteries = results[1];
      deceased = results[2];
      notifyListeners();
    } catch (_) {}
  }

  Future<List<Map<String, dynamic>>> loadImamsForMosque(int mosqueId) async {
    try {
      imams = await _service.getImams(mosqueId: mosqueId);
      notifyListeners();
      return imams;
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> loadGraveSitesForCemetery(int cemeteryId) async {
    try {
      graveSites = await _service.getAvailableGraveSites(cemeteryId);
      notifyListeners();
      return graveSites;
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

  Future<bool> delete(int id) async {
    try {
      await _service.delete(id);
      if (currentPage > 1 && appointments.length == 1) currentPage--;
      await loadAll();
      return true;
    } on DioException catch (e) {
      errorMessage = _parseError(e);
      notifyListeners();
      return false;
    }
  }

  void setFilter({
    int? mosqueId,
    int? imamId,
    String? status,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) {
    filterMosqueId = mosqueId;
    filterImamId = imamId;
    filterStatus = status;
    filterDateFrom = dateFrom;
    filterDateTo = dateTo;
    currentPage = 1;
    loadAll();
  }

  void resetFilters() {
    filterMosqueId = null;
    filterImamId = null;
    filterStatus = null;
    filterDateFrom = null;
    filterDateTo = null;
    currentPage = 1;
    loadAll();
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

  String _parseError(DioException e) {
    if (e.response?.statusCode == 401) return 'Sesija je istekla. Prijavite se ponovo.';
    if (e.response?.statusCode == 403) return 'Nemate ovlaštenja za ovu akciju.';
    final data = e.response?.data;
    if (data is Map && data['message'] != null) return data['message'] as String;
    return 'Neočekivana greška. Pokušajte ponovo.';
  }
}

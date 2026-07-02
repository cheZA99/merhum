import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../models/service_order_model.dart';
import '../services/service_order_service.dart';

class ServiceOrderProvider extends ChangeNotifier {
  final ServiceOrderService _service;
  ServiceOrderProvider(this._service);

  List<ServiceOrderModel> orders = [];
  List<Map<String, dynamic>> funeralHomes = [];
  List<Map<String, dynamic>> serviceTypes = [];
  List<Map<String, dynamic>> deceased = [];

  bool isLoading = false;
  String? errorMessage;
  int currentPage = 1;
  int totalCount = 0;
  static const int pageSize = 10;

  int? filterFuneralHomeId;
  String? filterStatus;
  DateTime? filterDateFrom;
  DateTime? filterDateTo;
  int? deceasedIdContext;

  List<ServiceOrderModel> pendingOrders = [];
  int pendingCount = 0;

  int get totalPages => (totalCount / pageSize).ceil().clamp(1, 99999);

  double get totalValue => orders.fold(0.0, (sum, o) => sum + o.price);

  Future<void> loadAll() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final (list, total) = await _service.getAll(
        deceasedId: deceasedIdContext,
        status: filterStatus,
        funeralHomeId: filterFuneralHomeId,
        dateFrom: filterDateFrom,
        dateTo: filterDateTo,
        pageNumber: currentPage,
        pageSize: pageSize,
      );
      orders = list;
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

  Future<void> loadPending() async {
    try {
      final results = await Future.wait([
        _service.getAll(status: 'Ordered', pageSize: 10),
        _service.getAll(status: 'InProgress', pageSize: 10),
      ]);
      final combined = [...results[0].$1, ...results[1].$1];
      combined.sort((a, b) => a.orderedAt.compareTo(b.orderedAt));
      pendingOrders = combined.take(5).toList();
      pendingCount = results[0].$2 + results[1].$2;
    } catch (_) {}
    notifyListeners();
  }

  Future<void> loadDropdownData() async {
    try {
      final results = await Future.wait([
        _service.getFuneralHomes(),
        _service.getServiceTypes(),
        _service.getDeceased(),
      ]);
      funeralHomes = results[0];
      serviceTypes = results[1];
      deceased = results[2];
      notifyListeners();
    } catch (_) {}
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
      if (currentPage > 1 && orders.length == 1) currentPage--;
      await loadAll();
      return true;
    } on DioException catch (e) {
      errorMessage = _parseError(e);
      notifyListeners();
      return false;
    }
  }

  void resetFilters() {
    filterFuneralHomeId = null;
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

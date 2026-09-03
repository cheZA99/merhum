import 'package:flutter/material.dart';
import '../models/service_order_model.dart';
import '../services/service_order_service.dart';
import '../utils/api_error.dart';

class ServiceOrderProvider extends ChangeNotifier {
  List<ServiceOrderModel> _orders = [];
  List<Map<String, dynamic>> _funeralHomes = [];
  List<Map<String, dynamic>> _serviceTypes = [];
  bool _isLoading = false;
  String? _error;

  List<ServiceOrderModel> get orders => _orders;
  List<Map<String, dynamic>> get funeralHomes => _funeralHomes;
  List<Map<String, dynamic>> get serviceTypes => _serviceTypes;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadForDeceased(int deceasedId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _orders = await ServiceOrderService.getByDeceasedId(deceasedId);
    } catch (e) {
      _orders = [];
      _error = parseApiError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMyOrders({String? status}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _orders = await ServiceOrderService.getMyOrders(status: status);
    } catch (e) {
      _orders = [];
      _error = parseApiError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadFuneralHomes() async {
    if (_funeralHomes.isNotEmpty) return;
    try {
      _funeralHomes = await ServiceOrderService.getFuneralHomes();
      notifyListeners();
    } catch (e) {
      _error = parseApiError(e);
      notifyListeners();
    }
  }

  Future<void> loadServiceTypes() async {
    if (_serviceTypes.isNotEmpty) return;
    try {
      _serviceTypes = await ServiceOrderService.getServiceTypes();
      notifyListeners();
    } catch (e) {
      _error = parseApiError(e);
      notifyListeners();
    }
  }

  Future<bool> create(Map<String, dynamic> body) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await ServiceOrderService.create(body);
      _orders.insert(0, result);
      return true;
    } catch (e) {
      _error = parseApiError(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateStatus(int id, String status) async {
    try {
      await ServiceOrderService.updateStatus(id, status);
      final idx = _orders.indexWhere((o) => o.id == id);
      if (idx != -1) {
        _orders[idx] = ServiceOrderModel(
          id: _orders[idx].id,
          deceasedId: _orders[idx].deceasedId,
          deceasedFullName: _orders[idx].deceasedFullName,
          funeralHomeId: _orders[idx].funeralHomeId,
          funeralHomeName: _orders[idx].funeralHomeName,
          serviceTypeId: _orders[idx].serviceTypeId,
          serviceTypeName: _orders[idx].serviceTypeName,
          price: _orders[idx].price,
          status: status,
          notes: _orders[idx].notes,
          orderedAt: _orders[idx].orderedAt,
        );
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = parseApiError(e);
      notifyListeners();
      return false;
    }
  }
}

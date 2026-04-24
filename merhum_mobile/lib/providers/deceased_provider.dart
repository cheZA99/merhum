import 'package:flutter/material.dart';
import '../models/deceased_model.dart';
import '../models/status_history_model.dart';
import '../services/deceased_service.dart';

class DeceasedProvider extends ChangeNotifier {
  List<DeceasedModel> _myDeceased = [];
  DeceasedModel? _selected;
  List<StatusHistoryModel> _statusHistory = [];
  List<Map<String, dynamic>> _cities = [];
  bool _isLoading = false;
  String? _error;

  List<DeceasedModel> get myDeceased => _myDeceased;
  DeceasedModel? get selected => _selected;
  List<StatusHistoryModel> get statusHistory => _statusHistory;
  List<Map<String, dynamic>> get cities => _cities;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadMyDeceased() async {
    _isLoading = true;
    notifyListeners();
    try {
      _myDeceased = await DeceasedService.getMyDeceased();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadById(int id) async {
    _isLoading = true;
    notifyListeners();
    try {
      _selected = await DeceasedService.getById(id);
      _statusHistory = await DeceasedService.getStatusHistory(id);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<DeceasedModel?> create(Map<String, dynamic> body) async {
    _isLoading = true;
    notifyListeners();
    try {
      final result = await DeceasedService.create(body);
      _myDeceased.insert(0, result);
      return result;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadCities() async {
    if (_cities.isNotEmpty) return;
    try {
      _cities = await DeceasedService.getCities();
      notifyListeners();
    } catch (_) {}
  }
}

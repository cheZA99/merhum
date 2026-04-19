import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';

class UserProvider extends ChangeNotifier {
  final UserService _service;
  UserProvider(this._service);

  List<UserModel> _users = [];
  List<UserModel> get users => _users;

  int _totalCount = 0;
  int get totalCount => _totalCount;

  int _currentPage = 1;
  int get currentPage => _currentPage;
  set currentPage(int v) {
    _currentPage = v;
    notifyListeners();
  }

  static const int _pageSize = 10;
  int get totalPages => (_totalCount / _pageSize).ceil().clamp(1, 9999);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? filterName;
  String? filterRole;
  bool? filterIsLocked;

  List<Map<String, dynamic>> _cities = [];
  List<Map<String, dynamic>> get cities => _cities;

  Future<void> loadAll() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final (items, total) = await _service.getAll(
        name: filterName,
        role: filterRole,
        isLocked: filterIsLocked,
        pageNumber: _currentPage,
        pageSize: _pageSize,
      );
      _users = items;
      _totalCount = total;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadCities() async {
    try {
      _cities = await _service.getCities();
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> create(Map<String, dynamic> data) async {
    try {
      await _service.create(data);
      await loadAll();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> update(String id, Map<String, dynamic> data) async {
    try {
      await _service.update(id, data);
      await loadAll();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleLock(String id) async {
    try {
      await _service.toggleLock(id);
      await loadAll();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> changeRole(String id, String role) async {
    try {
      await _service.changeRole(id, role);
      await loadAll();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> resetPassword(String id) async {
    try {
      await _service.resetPassword(id);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  void resetFilters() {
    filterName = null;
    filterRole = null;
    filterIsLocked = null;
    _currentPage = 1;
    loadAll();
  }

  void nextPage() {
    if (_currentPage < totalPages) {
      _currentPage++;
      loadAll();
    }
  }

  void previousPage() {
    if (_currentPage > 1) {
      _currentPage--;
      loadAll();
    }
  }
}

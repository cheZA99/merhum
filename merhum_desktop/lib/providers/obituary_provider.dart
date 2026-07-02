import 'package:flutter/foundation.dart';
import '../models/obituary_model.dart';
import '../services/obituary_service.dart';

class ObituaryProvider extends ChangeNotifier {
  final ObituaryService _service;

  ObituaryProvider(this._service);

  List<ObituaryModel> _obituaries = [];
  List<ObituaryModel> get obituaries => _obituaries;

  int _totalCount = 0;
  int get totalCount => _totalCount;

  int _currentPage = 1;
  int get currentPage => _currentPage;
  set currentPage(int v) {
    _currentPage = v;
    notifyListeners();
  }

  int get totalPages => (_totalCount / _pageSize).ceil().clamp(1, 9999);
  final int _pageSize = 20;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool? filterIsPublic;
  bool? filterIsActive;
  String? filterDeceasedName;

  List<Map<String, dynamic>> _deceased = [];
  List<Map<String, dynamic>> get deceased => _deceased;

  ObituaryModel? _selected;
  ObituaryModel? get selected => _selected;

  int _todayCount = 0;
  int get todayCount => _todayCount;

  Future<void> loadTodayCount() async {
    try {
      _todayCount = await _service.getTodayCount();
    } catch (_) {}
    notifyListeners();
  }

  Future<void> loadAll() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final (items, total) = await _service.getAll(
        isPublic: filterIsPublic,
        isActive: filterIsActive,
        deceasedName: filterDeceasedName,
        pageNumber: _currentPage,
        pageSize: _pageSize,
      );
      _obituaries = items;
      _totalCount = total;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadById(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _selected = await _service.getById(id);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadDeceasedDropdown() async {
    try {
      _deceased = await _service.getDeceased();
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> create(int deceasedId, bool isPublic) async {
    try {
      await _service.create(deceasedId, isPublic);
      await loadAll();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> update(int id, {required bool isPublic, required bool isActive}) async {
    try {
      await _service.update(id, isPublic: isPublic, isActive: isActive);
      await loadAll();
      if (_selected?.id == id) await loadById(id);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> delete(int id) async {
    try {
      await _service.delete(id);
      await loadAll();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> approveCondolence(int condolenceId) async {
    try {
      await _service.approveCondolence(condolenceId);
      if (_selected != null) await loadById(_selected!.id);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteCondolence(int condolenceId) async {
    try {
      await _service.deleteCondolence(condolenceId);
      if (_selected != null) await loadById(_selected!.id);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  void resetFilters() {
    filterIsPublic = null;
    filterIsActive = null;
    filterDeceasedName = null;
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

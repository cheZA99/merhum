import 'package:flutter/material.dart';
import '../models/obituary_model.dart';
import '../models/condolence_model.dart';
import '../services/obituary_service.dart';

class ObituaryProvider extends ChangeNotifier {
  List<ObituaryModel> _results = [];
  List<ObituaryModel> _recent = [];
  ObituaryModel? _detail;
  List<CondolenceModel> _condolences = [];
  List<Map<String, dynamic>> _upcomingFunerals = [];
  bool _isLoading = false;
  bool _isLoadingDetail = false;
  String? _error;

  List<ObituaryModel> get results => _results;
  List<ObituaryModel> get recent => _recent;
  ObituaryModel? get detail => _detail;
  List<CondolenceModel> get condolences => _condolences;
  List<Map<String, dynamic>> get upcomingFunerals => _upcomingFunerals;
  bool get isLoading => _isLoading;
  bool get isLoadingDetail => _isLoadingDetail;
  String? get error => _error;

  Future<void> search(String? query) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _results = await ObituaryService.search(query);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadRecent() async {
    try {
      _recent = await ObituaryService.search(null, pageSize: 5);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> loadDetail(String slug) async {
    _isLoadingDetail = true;
    _detail = null;
    notifyListeners();
    try {
      _detail = await ObituaryService.getBySlug(slug);
      await _loadCondolences(slug);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingDetail = false;
      notifyListeners();
    }
  }

  Future<void> _loadCondolences(String slug) async {
    try {
      _condolences = await ObituaryService.getCondolences(slug);
    } catch (_) {
      _condolences = [];
    }
  }

  Future<void> loadUpcomingFunerals({int? cityId}) async {
    _isLoading = true;
    notifyListeners();
    try {
      _upcomingFunerals = await ObituaryService.getUpcomingFunerals(cityId: cityId);
    } catch (_) {
      _upcomingFunerals = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addCondolence(String slug, String authorName, String text) async {
    try {
      await ObituaryService.addCondolence(slug, authorName, text);
      await _loadCondolences(slug);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }
}

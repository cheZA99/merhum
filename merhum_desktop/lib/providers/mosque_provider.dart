import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../models/mosque_model.dart';
import '../services/mosque_service.dart';

class MosqueProvider extends ChangeNotifier {
  final MosqueService _service;

  MosqueProvider(this._service);

  List<MosqueModel> _svi = [];
  List<Map<String, dynamic>> gradovi = [];
  bool isLoading = false;
  String? errorMessage;
  String? searchNaziv;
  int? filterGradId;

  // Client-side city filter — the API does not support filtering by cityId
  List<MosqueModel> get stavke {
    if (filterGradId == null) return _svi;
    return _svi.where((m) => m.gradId == filterGradId).toList();
  }

  Future<void> loadAll() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      _svi = await _service.getAll(search: searchNaziv);
    } on DioException catch (e) {
      errorMessage = _parseError(e);
    } catch (e) {
      errorMessage = 'Greska pri ucitavanju.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadGradovi() async {
    try {
      gradovi = await _service.getGradovi();
    } catch (_) {
    }
    notifyListeners();
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

  Future<bool> delete(int id) async {
    try {
      await _service.delete(id);
      _svi.removeWhere((m) => m.id == id);
      notifyListeners();
      return true;
    } on DioException catch (e) {
      errorMessage = _parseError(e);
      notifyListeners();
      return false;
    }
  }

  void setSearch(String naziv) {
    searchNaziv = naziv.isEmpty ? null : naziv;
    loadAll();
  }

  void setFilterGrad(int? gradId) {
    filterGradId = gradId;
    notifyListeners(); // re-filter only, no API call
  }

  String _parseError(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      return data['message'] as String? ?? data['title'] as String? ?? 'Greska na serveru.';
    }
    if (e.type == DioExceptionType.connectionError) return 'Nema veze sa serverom.';
    if (e.response?.statusCode == 404) return 'Mesdid nije pronadjen.';
    if (e.response?.statusCode == 409) return 'Mesdid s tim imenom vec postoji.';
    return 'Neocekivana greska (${e.response?.statusCode}).';
  }
}

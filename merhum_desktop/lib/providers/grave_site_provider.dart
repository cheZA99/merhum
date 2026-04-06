import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../models/grave_site_model.dart';
import '../services/grave_site_service.dart';

class GraveSiteProvider extends ChangeNotifier {
  final GraveSiteService _service;
  GraveSiteProvider(this._service);

  List<GraveSiteModel> sites = [];
  List<GraveSiteModel> mapData = [];
  List<Map<String, dynamic>> deceased = [];
  List<Map<String, dynamic>> sectors = [];
  bool isLoading = false;
  bool isLoadingMap = false;
  String? errorMessage;

  int? filterCemeteryId;
  String? filterStatus;
  int currentPage = 1;
  int totalPages = 1;
  static const int pageSize = 20;

  Future<void> loadAll({int page = 1}) async {
    isLoading = true;
    errorMessage = null;
    currentPage = page;
    notifyListeners();
    try {
      final result = await _service.getAll(
        cemeteryId: filterCemeteryId,
        status: filterStatus,
        pageNumber: page,
        pageSize: pageSize,
      );
      sites = result;
      totalPages = result.length < pageSize ? page : page + 1;
    } on DioException catch (e) {
      errorMessage = _parseError(e);
    } catch (e) {
      errorMessage = 'Error loading: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMapData(int cemeteryId) async {
    isLoadingMap = true;
    notifyListeners();
    try {
      mapData = await _service.getMapData(cemeteryId);
    } catch (_) {
      mapData = [];
    } finally {
      isLoadingMap = false;
      notifyListeners();
    }
  }

  Future<void> loadDeceased({int? currentDeceasedId}) async {
    try {
      deceased = await _service.getDeceased(currentDeceasedId: currentDeceasedId);
    } catch (_) {}
    // Clear stale error — prevents the list screen from showing an old error
    // when the form opens and triggers a rebuild
    errorMessage = null;
    notifyListeners();
  }

  Future<void> loadSectors(int cemeteryId) async {
    try {
      sectors = await _service.getSectors(cemeteryId);
    } catch (_) {
      sectors = [];
    }
    errorMessage = null;
    notifyListeners();
  }

  Future<bool> create(Map<String, dynamic> data,
      {int? deceasedId, String? status}) async {
    try {
      final newId = await _service.create(data);
      // Apply non-default status after creation
      if (status != null && status != 'Available' && newId > 0) {
        await _service.updateStatus(newId, status);
      }
      if (deceasedId != null && newId > 0) {
        await _service.assignDeceased(newId, deceasedId);
      }
      await loadAll(page: currentPage);
      if (filterCemeteryId != null) loadMapData(filterCemeteryId!);
      return true;
    } on DioException catch (e) {
      errorMessage = _parseError(e);
      notifyListeners();
      return false;
    } catch (e) {
      errorMessage = 'Error: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> update(int id, Map<String, dynamic> data,
      {int? deceasedId,
      bool assignChanged = false,
      String? newStatus,
      String? oldStatus}) async {
    try {
      await _service.update(id, data);

      final statusChanged = newStatus != null && newStatus != oldStatus;

      if (statusChanged) {
        if (oldStatus == 'Occupied' && newStatus != 'Occupied') {
          // Unassign deceased because the site is no longer occupied
          await _service.unassignDeceased(id);
          // If the new status is Reserved, set it explicitly — unassign resets to Available
          if (newStatus == 'Reserved') {
            await _service.updateStatus(id, newStatus);
          }
        } else if (newStatus == 'Occupied' && deceasedId != null) {
          await _service.assignDeceased(id, deceasedId);
        } else {
          await _service.updateStatus(id, newStatus);
        }
      } else if (assignChanged && deceasedId != null) {
        // Status remains Occupied but the assigned deceased changed
        await _service.assignDeceased(id, deceasedId);
      }

      await loadAll(page: currentPage);
      if (filterCemeteryId != null) loadMapData(filterCemeteryId!);
      return true;
    } on DioException catch (e) {
      errorMessage = _parseError(e);
      notifyListeners();
      return false;
    } catch (e) {
      errorMessage = 'Error: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> delete(int id) async {
    try {
      await _service.delete(id);
      sites.removeWhere((m) => m.id == id);
      notifyListeners();
      return true;
    } on DioException catch (e) {
      errorMessage = _parseError(e);
      notifyListeners();
      return false;
    } catch (e) {
      errorMessage = 'Error: $e';
      notifyListeners();
      return false;
    }
  }

  void setFilterCemetery(int? cemeteryId) {
    filterCemeteryId = cemeteryId;
    currentPage = 1;
    loadAll();
    if (cemeteryId != null) {
      loadMapData(cemeteryId);
      loadSectors(cemeteryId);
    }
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }

  void setFilterStatus(String? status) {
    filterStatus = status;
    currentPage = 1;
    loadAll();
  }

  String _parseError(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      return data['message'] as String? ??
          data['title'] as String? ??
          'Server error.';
    }
    if (e.type == DioExceptionType.connectionError) return 'No server connection.';
    return 'HTTP ${e.response?.statusCode ?? "?"}';
  }
}

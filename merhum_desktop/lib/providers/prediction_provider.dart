import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../models/cemetery_prediction_model.dart';
import '../services/prediction_service.dart';

class PredictionProvider extends ChangeNotifier {
  final PredictionService _service;
  PredictionProvider(this._service);

  List<CemeteryPredictionModel> predictions = [];
  bool isLoading = false;
  bool isTraining = false;
  String? errorMessage;

  Future<void> loadAll() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      predictions = await _service.getAllPredictions();
    } on DioException catch (e) {
      errorMessage = _parseError(e);
    } catch (_) {
      errorMessage = 'Greška pri učitavanju predviđanja.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> trainModel() async {
    isTraining = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _service.trainModel();
      await loadAll();
      return true;
    } on DioException catch (e) {
      errorMessage = _parseError(e);
      return false;
    } catch (_) {
      errorMessage = 'Greška pri treniranju modela.';
      return false;
    } finally {
      isTraining = false;
      notifyListeners();
    }
  }

  String _parseError(DioException e) {
    final data = e.response?.data;
    if (data is Map) return data['message'] as String? ?? 'Greška na serveru.';
    if (e.type == DioExceptionType.connectionError) return 'Nema veze sa serverom.';
    return 'Greška (${e.response?.statusCode}).';
  }
}

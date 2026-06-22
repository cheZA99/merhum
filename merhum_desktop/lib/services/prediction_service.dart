import '../models/cemetery_prediction_model.dart';
import 'api_service.dart';

class PredictionService {
  final ApiService _api;
  PredictionService(this._api);

  Future<void> trainModel() async {
    await _api.post('/api/predikcije/treniraj');
  }

  Future<CemeteryPredictionModel> getPrediction(int cemeteryId) async {
    final response = await _api.get('/api/predikcije/groblje/$cemeteryId');
    final raw = response.data as Map<String, dynamic>;
    return CemeteryPredictionModel.fromJson(raw['data'] as Map<String, dynamic>);
  }

  Future<List<CemeteryPredictionModel>> getAllPredictions() async {
    final response = await _api.get('/api/predikcije/sva-groblja');
    final raw = response.data as Map<String, dynamic>;
    final list = raw['data'] as List? ?? [];
    return list
        .map((e) => CemeteryPredictionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

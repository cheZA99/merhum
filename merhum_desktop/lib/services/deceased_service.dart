import '../models/deceased_model.dart';
import '../models/procedure_status_model.dart';
import '../models/status_history_model.dart';
import 'api_service.dart';

class DeceasedService {
  final ApiService _api;
  DeceasedService(this._api);

  Future<List<DeceasedModel>> getAll({
    String? search,
    int? statusId,
    int? cityId,
  }) async {
    final params = <String, dynamic>{};
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (statusId != null) params['statusId'] = statusId;
    if (cityId != null) params['cityId'] = cityId;
    final response = await _api.get('/api/deceased', queryParams: params);
    final raw = response.data;
    final list = raw is List ? raw : (raw['data'] as List? ?? []);
    return list
        .map((e) => DeceasedModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<DeceasedModel> getById(int id) async {
    final response = await _api.get('/api/deceased/$id');
    final raw = response.data;
    final obj =
        raw is Map<String, dynamic> ? raw : (raw['data'] as Map<String, dynamic>);
    return DeceasedModel.fromJson(obj);
  }

  Future<List<StatusHistoryModel>> getStatusHistory(int id) async {
    final response = await _api.get('/api/deceased/$id/status-history');
    final raw = response.data;
    final list = raw is List ? raw : (raw['data'] as List? ?? []);
    return list
        .map((e) => StatusHistoryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<DeceasedModel> create(Map<String, dynamic> data) async {
    final response = await _api.post('/api/deceased', data: data);
    final raw = response.data;
    final obj =
        raw is Map<String, dynamic> ? raw : (raw['data'] as Map<String, dynamic>);
    return DeceasedModel.fromJson(obj);
  }

  Future<void> update(int id, Map<String, dynamic> data) async {
    await _api.put('/api/deceased/$id', data: data);
  }

  Future<void> updateStatus(int id, int statusId, String? note) async {
    await _api.patch(
      '/api/deceased/$id/status',
      data: {'statusId': statusId, 'note': note},
    );
  }

  Future<void> delete(int id) async {
    await _api.delete('/api/deceased/$id');
  }

  Future<List<ProcedureStatusModel>> getStatuses() async {
    final response = await _api.get('/api/referencedata/procedure-statuses');
    final raw = response.data;
    final list = raw is List ? raw : (raw['data'] as List? ?? []);
    return list
        .map((e) => ProcedureStatusModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Map<String, dynamic>>> getCities() async {
    final response = await _api.get('/api/referencedata/cities');
    final raw = response.data;
    final list = raw is List ? raw : (raw['data'] as List? ?? []);
    return list.cast<Map<String, dynamic>>();
  }
}

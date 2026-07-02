import '../models/grave_site_model.dart';
import 'api_service.dart';

class GraveSiteService {
  final ApiService _api;
  GraveSiteService(this._api);

  Future<List<GraveSiteModel>> getAll({
    int? cemeteryId,
    String? status,
    int pageNumber = 1,
    int pageSize = 20,
  }) async {
    final params = <String, dynamic>{
      'pageNumber': pageNumber,
      'pageSize': pageSize,
    };
    if (cemeteryId != null) params['cemeteryId'] = cemeteryId;
    if (status != null && status.isNotEmpty) params['status'] = status;

    final response = await _api.get('/api/gravesite', queryParams: params);
    final raw = response.data as Map<String, dynamic>;
    final list = raw['data'] as List? ?? raw['items'] as List? ?? [];
    return list.map((e) => GraveSiteModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<int> getFreeCount() async {
    final response = await _api.get('/api/gravesite', queryParams: {
      'status': 'Available',
      'pageSize': 1,
    });
    final raw = response.data as Map<String, dynamic>;
    return raw['totalCount'] as int? ?? 0;
  }

  Future<List<GraveSiteModel>> getMapData(int cemeteryId) async {
    final response = await _api.get('/api/gravesite', queryParams: {
      'cemeteryId': cemeteryId,
      'pageSize': 1000,
    });
    final raw = response.data as Map<String, dynamic>;
    final list = raw['data'] as List? ?? raw['items'] as List? ?? [];
    return list.map((e) => GraveSiteModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<GraveSiteModel> getById(int id) async {
    final response = await _api.get('/api/gravesite/$id');
    final raw = response.data as Map<String, dynamic>;
    return GraveSiteModel.fromJson(raw['data'] as Map<String, dynamic>);
  }

  Future<int> create(Map<String, dynamic> data) async {
    final response = await _api.post('/api/gravesite', data: data);
    // 201 returns just the id, no need to parse the whole model
    final raw = response.data;
    if (raw is Map) {
      final inner = raw['data'];
      if (inner is Map) return (inner['id'] as int?) ?? 0;
    }
    return 0;
  }

  Future<void> update(int id, Map<String, dynamic> data) async {
    await _api.put('/api/gravesite/$id', data: data);
  }

  Future<void> updateStatus(int id, String status) async {
    await _api.patch('/api/gravesite/$id/status', data: {'status': status});
  }

  Future<void> assignDeceased(int graveSiteId, int deceasedId) async {
    await _api.patch('/api/gravesite/$graveSiteId/assign',
        data: {'deceasedId': deceasedId});
  }

  Future<void> unassignDeceased(int graveSiteId) async {
    await _api.patch('/api/gravesite/$graveSiteId/unassign');
  }

  Future<void> delete(int id) async {
    await _api.delete('/api/gravesite/$id');
  }

  // in edit mode keep the already-assigned deceased in the list
  Future<List<Map<String, dynamic>>> getDeceased({int? currentDeceasedId}) async {
    final response = await _api.get('/api/deceased', queryParams: {
      'pageSize': 500,
      'withoutGraveSite': true,
    });
    final raw = response.data;
    final list = raw is Map
        ? (raw['data'] as List? ?? raw['items'] as List? ?? [])
        : (raw as List? ?? []);
    final result = list.cast<Map<String, dynamic>>();

    // inject the assigned deceased manually when editing
    if (currentDeceasedId != null &&
        !result.any((p) => p['id'] == currentDeceasedId)) {
      try {
        final detailRes = await _api.get('/api/deceased/$currentDeceasedId');
        final detail = detailRes.data;
        final obj = detail is Map ? detail['data'] ?? detail : null;
        if (obj != null) result.insert(0, (obj as Map).cast<String, dynamic>());
      } catch (_) {}
    }

    return result;
  }

  Future<List<Map<String, dynamic>>> getSectors(int cemeteryId) async {
    // no endpoint for this, derive sectors from the gravesite list
    final sites = await getAll(cemeteryId: cemeteryId, pageSize: 500);
    final seen = <int>{};
    return sites
        .where((m) => m.sectorId != null && seen.add(m.sectorId!))
        .map((m) => {'id': m.sectorId, 'name': m.sectorName})
        .toList();
  }
}

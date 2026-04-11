import '../models/appointment_model.dart';
import 'api_service.dart';

class AppointmentService {
  final ApiService _api;
  AppointmentService(this._api);

  Future<(List<AppointmentModel>, int)> getAll({
    int? deceasedId,
    String? status,
    int? mosqueId,
    int? imamId,
    DateTime? dateFrom,
    DateTime? dateTo,
    int pageNumber = 1,
    int pageSize = 10,
  }) async {
    final params = <String, dynamic>{
      'pageNumber': pageNumber,
      'pageSize': pageSize,
    };
    if (deceasedId != null) params['deceasedId'] = deceasedId;
    if (status != null && status.isNotEmpty) params['status'] = status;
    if (mosqueId != null) params['mosqueId'] = mosqueId;
    if (imamId != null) params['imamId'] = imamId;
    if (dateFrom != null) params['dateFrom'] = dateFrom.toIso8601String();
    if (dateTo != null) params['dateTo'] = dateTo.toIso8601String();

    final response = await _api.get('/api/appointment', queryParams: params);
    final raw = response.data as Map<String, dynamic>;
    final list = raw['data'] as List? ?? [];
    final total = raw['totalCount'] as int? ?? 0;
    return (
      list.map((e) => AppointmentModel.fromJson(e as Map<String, dynamic>)).toList(),
      total,
    );
  }

  Future<AppointmentModel> getById(int id) async {
    final response = await _api.get('/api/appointment/$id');
    final raw = response.data as Map<String, dynamic>;
    return AppointmentModel.fromJson(raw['data'] as Map<String, dynamic>);
  }

  Future<AppointmentModel> create(Map<String, dynamic> data) async {
    final response = await _api.post('/api/appointment', data: data);
    final raw = response.data as Map<String, dynamic>;
    return AppointmentModel.fromJson(raw['data'] as Map<String, dynamic>);
  }

  Future<AppointmentModel> update(int id, Map<String, dynamic> data) async {
    final response = await _api.put('/api/appointment/$id', data: data);
    final raw = response.data as Map<String, dynamic>;
    return AppointmentModel.fromJson(raw['data'] as Map<String, dynamic>);
  }

  Future<void> delete(int id) async {
    await _api.delete('/api/appointment/$id');
  }

  Future<List<Map<String, dynamic>>> getMosques() async {
    final response = await _api.get('/api/mosque', queryParams: {'pageSize': 500});
    final raw = response.data as Map<String, dynamic>;
    final list = raw['data'] as List? ?? [];
    return list.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> getCemeteries() async {
    final response = await _api.get('/api/cemetery', queryParams: {'pageSize': 500});
    final raw = response.data as Map<String, dynamic>;
    final list = raw['data'] as List? ?? [];
    return list.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> getImams({int? mosqueId}) async {
    final params = <String, dynamic>{'pageSize': 500};
    if (mosqueId != null) params['mosqueId'] = mosqueId;
    final response = await _api.get('/api/imam', queryParams: params);
    final raw = response.data as Map<String, dynamic>;
    final list = raw['data'] as List? ?? [];
    return list.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> getAvailableGraveSites(int cemeteryId) async {
    final response = await _api.get('/api/gravesite', queryParams: {
      'cemeteryId': cemeteryId,
      'status': 'Free',
      'pageSize': 500,
    });
    final raw = response.data as Map<String, dynamic>;
    final list = raw['data'] as List? ?? [];
    return list.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> getDeceased() async {
    final response = await _api.get('/api/deceased');
    final raw = response.data;
    final list = raw is List ? raw : (raw['data'] as List? ?? []);
    return list.cast<Map<String, dynamic>>();
  }
}

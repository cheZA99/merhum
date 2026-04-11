import '../models/service_order_model.dart';
import 'api_service.dart';

class ServiceOrderService {
  final ApiService _api;
  ServiceOrderService(this._api);

  Future<(List<ServiceOrderModel>, int)> getAll({
    int? deceasedId,
    String? status,
    int? funeralHomeId,
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
    if (funeralHomeId != null) params['funeralHomeId'] = funeralHomeId;
    if (dateFrom != null) params['dateFrom'] = dateFrom.toIso8601String();
    if (dateTo != null) params['dateTo'] = dateTo.toIso8601String();

    final response = await _api.get('/api/serviceorder', queryParams: params);
    final raw = response.data as Map<String, dynamic>;
    final list = raw['data'] as List? ?? [];
    final total = raw['totalCount'] as int? ?? 0;
    return (
      list.map((e) => ServiceOrderModel.fromJson(e as Map<String, dynamic>)).toList(),
      total,
    );
  }

  Future<ServiceOrderModel> getById(int id) async {
    final response = await _api.get('/api/serviceorder/$id');
    final raw = response.data as Map<String, dynamic>;
    return ServiceOrderModel.fromJson(raw['data'] as Map<String, dynamic>);
  }

  Future<ServiceOrderModel> create(Map<String, dynamic> data) async {
    final response = await _api.post('/api/serviceorder', data: data);
    final raw = response.data as Map<String, dynamic>;
    return ServiceOrderModel.fromJson(raw['data'] as Map<String, dynamic>);
  }

  Future<ServiceOrderModel> update(int id, Map<String, dynamic> data) async {
    final response = await _api.put('/api/serviceorder/$id', data: data);
    final raw = response.data as Map<String, dynamic>;
    return ServiceOrderModel.fromJson(raw['data'] as Map<String, dynamic>);
  }

  Future<void> delete(int id) async {
    await _api.delete('/api/serviceorder/$id');
  }

  Future<List<Map<String, dynamic>>> getFuneralHomes() async {
    final response = await _api.get('/api/funeralhome', queryParams: {'pageSize': 500});
    final raw = response.data as Map<String, dynamic>;
    final list = raw['data'] as List? ?? [];
    return list.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> getServiceTypes() async {
    final response = await _api.get('/api/referencedata/service-types');
    final raw = response.data;
    final list = raw is List ? raw : (raw['data'] as List? ?? []);
    return list.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> getDeceased() async {
    final response = await _api.get('/api/deceased');
    final raw = response.data;
    final list = raw is List ? raw : (raw['data'] as List? ?? []);
    return list.cast<Map<String, dynamic>>();
  }
}

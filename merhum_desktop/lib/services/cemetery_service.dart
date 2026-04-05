import '../models/cemetery_model.dart';
import 'api_service.dart';

class CemeteryService {
  final ApiService _api;
  CemeteryService(this._api);

  Future<List<CemeteryModel>> getAll({String? name}) async {
    final params = <String, dynamic>{'pageSize': 500};
    if (name != null && name.isNotEmpty) params['search'] = name;

    final response = await _api.get('/api/cemetery', queryParams: params);
    final raw = response.data as Map<String, dynamic>;
    final list = raw['data'] as List? ?? [];
    return list.map((e) => CemeteryModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<CemeteryModel> getById(int id) async {
    final response = await _api.get('/api/cemetery/$id');
    final raw = response.data as Map<String, dynamic>;
    return CemeteryModel.fromJson(raw['data'] as Map<String, dynamic>);
  }

  Future<CemeteryModel> create(Map<String, dynamic> data) async {
    final response = await _api.post('/api/cemetery', data: data);
    final raw = response.data as Map<String, dynamic>;
    return CemeteryModel.fromJson(raw['data'] as Map<String, dynamic>);
  }

  Future<void> update(int id, Map<String, dynamic> data) async {
    await _api.put('/api/cemetery/$id', data: data);
  }

  Future<void> delete(int id) async {
    await _api.delete('/api/cemetery/$id');
  }

  Future<List<Map<String, dynamic>>> getCities() async {
    final response = await _api.get('/api/referencedata/cities');
    final raw = response.data;
    final list = raw is List ? raw : (raw['data'] as List? ?? []);
    return list.cast<Map<String, dynamic>>();
  }
}

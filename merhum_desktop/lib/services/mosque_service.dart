import '../models/mosque_model.dart';
import 'api_service.dart';

class MosqueService {
  final ApiService _api;
  MosqueService(this._api);

  Future<List<MosqueModel>> getAll({String? search}) async {
    final params = <String, dynamic>{
      'pageSize': 500,
    };
    if (search != null && search.isNotEmpty) params['search'] = search;

    final response = await _api.get('/api/mosque', queryParams: params);
    final raw = response.data as Map<String, dynamic>;

    // PagedResponse<T>, data is the list
    final list = raw['data'] as List? ?? [];
    return list.map((e) => MosqueModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<MosqueModel> getById(int id) async {
    final response = await _api.get('/api/mosque/$id');
    final raw = response.data as Map<String, dynamic>;
    return MosqueModel.fromJson(raw['data'] as Map<String, dynamic>);
  }

  Future<MosqueModel> create(Map<String, dynamic> data) async {
    final response = await _api.post('/api/mosque', data: data);
    final raw = response.data as Map<String, dynamic>;
    return MosqueModel.fromJson(raw['data'] as Map<String, dynamic>);
  }

  // PUT returns 204, caller refreshes
  Future<void> update(int id, Map<String, dynamic> data) async {
    await _api.put('/api/mosque/$id', data: data);
  }

  Future<void> delete(int id) async {
    await _api.delete('/api/mosque/$id');
  }

  Future<List<Map<String, dynamic>>> getCities() async {
    final response = await _api.get('/api/referencedata/cities');
    final raw = response.data;
    final list = raw is List ? raw : (raw['data'] as List? ?? []);
    return list.cast<Map<String, dynamic>>();
  }
}

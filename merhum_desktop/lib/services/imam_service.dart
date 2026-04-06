import '../models/imam_model.dart';
import 'api_service.dart';

class ImamService {
  final ApiService _api;
  ImamService(this._api);

  Future<(List<ImamModel>, int)> getAll({
    int? mosqueId,
    bool? isActive,
    String? name,
    int pageNumber = 1,
    int pageSize = 10,
  }) async {
    final params = <String, dynamic>{
      'pageNumber': pageNumber,
      'pageSize': pageSize,
    };
    if (mosqueId != null) params['mosqueId'] = mosqueId;
    if (isActive != null) params['isActive'] = isActive;
    if (name != null && name.isNotEmpty) params['name'] = name;

    final response = await _api.get('/api/imam', queryParams: params);
    final raw = response.data as Map<String, dynamic>;
    final list = raw['data'] as List? ?? [];
    final items = list
        .map((e) => ImamModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final totalCount =
        raw['totalCount'] as int? ?? raw['total'] as int? ?? items.length;
    return (items, totalCount);
  }

  Future<ImamModel> getById(int id) async {
    final response = await _api.get('/api/imam/$id');
    final raw = response.data as Map<String, dynamic>;
    return ImamModel.fromJson(raw['data'] as Map<String, dynamic>);
  }

  Future<ImamModel> create(Map<String, dynamic> data) async {
    final response = await _api.post('/api/imam', data: data);
    final raw = response.data as Map<String, dynamic>;
    return ImamModel.fromJson(raw['data'] as Map<String, dynamic>);
  }

  Future<void> update(int id, Map<String, dynamic> data) async {
    await _api.put('/api/imam/$id', data: data);
  }

  Future<void> delete(int id) async {
    await _api.delete('/api/imam/$id');
  }

  Future<List<Map<String, dynamic>>> getMosques() async {
    final response =
        await _api.get('/api/mosque', queryParams: {'pageSize': 500});
    final raw = response.data as Map<String, dynamic>;
    final list = raw['data'] as List? ?? [];
    return list.cast<Map<String, dynamic>>();
  }
}

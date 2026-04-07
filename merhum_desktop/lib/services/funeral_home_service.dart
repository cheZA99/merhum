import '../models/funeral_home_model.dart';
import 'api_service.dart';

class FuneralHomeService {
  final ApiService _api;
  FuneralHomeService(this._api);

  Future<(List<FuneralHomeModel>, int)> getAll({
    String? search,
    int pageNumber = 1,
    int pageSize = 10,
  }) async {
    final params = <String, dynamic>{
      'pageNumber': pageNumber,
      'pageSize': pageSize,
    };
    if (search != null && search.isNotEmpty) params['search'] = search;

    final response = await _api.get('/api/funeralhome', queryParams: params);
    final raw = response.data as Map<String, dynamic>;
    final list = raw['data'] as List? ?? [];
    final items = list
        .map((e) => FuneralHomeModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final totalCount =
        raw['totalCount'] as int? ?? raw['total'] as int? ?? items.length;
    return (items, totalCount);
  }

  Future<FuneralHomeModel> getById(int id) async {
    final response = await _api.get('/api/funeralhome/$id');
    final raw = response.data as Map<String, dynamic>;
    return FuneralHomeModel.fromJson(raw['data'] as Map<String, dynamic>);
  }

  Future<FuneralHomeModel> create(Map<String, dynamic> data) async {
    final response = await _api.post('/api/funeralhome', data: data);
    final raw = response.data as Map<String, dynamic>;
    return FuneralHomeModel.fromJson(raw['data'] as Map<String, dynamic>);
  }

  Future<void> update(int id, Map<String, dynamic> data) async {
    await _api.put('/api/funeralhome/$id', data: data);
  }

  Future<void> delete(int id) async {
    await _api.delete('/api/funeralhome/$id');
  }

  Future<List<Map<String, dynamic>>> getCities() async {
    final response = await _api.get('/api/referencedata/cities');
    final raw = response.data;
    final list = raw is List ? raw : (raw['data'] as List? ?? []);
    return list.cast<Map<String, dynamic>>();
  }
}

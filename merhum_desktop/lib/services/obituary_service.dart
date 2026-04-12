import '../models/obituary_model.dart';
import 'api_service.dart';

class ObituaryService {
  final ApiService _api;
  ObituaryService(this._api);

  Future<(List<ObituaryModel>, int)> getAll({
    bool? isPublic,
    bool? isActive,
    String? deceasedName,
    int pageNumber = 1,
    int pageSize = 20,
  }) async {
    final params = <String, dynamic>{
      'pageNumber': pageNumber,
      'pageSize': pageSize,
    };
    if (isPublic != null) params['isPublic'] = isPublic;
    if (isActive != null) params['isActive'] = isActive;
    if (deceasedName != null && deceasedName.isNotEmpty) {
      params['deceasedName'] = deceasedName;
    }

    final response = await _api.get('/api/obituary', queryParams: params);
    final data = response.data as Map<String, dynamic>;
    final items = (data['data'] as List<dynamic>)
        .map((e) => ObituaryModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final total = data['totalCount'] as int;
    return (items, total);
  }

  Future<ObituaryModel?> getById(int id) async {
    final response = await _api.get('/api/obituary/$id');
    final data = response.data as Map<String, dynamic>;
    return ObituaryModel.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<bool> create(int deceasedId, bool isPublic) async {
    await _api.post('/api/obituary', data: {
      'deceasedId': deceasedId,
      'isPublic': isPublic,
    });
    return true;
  }

  Future<bool> update(int id, {required bool isPublic, required bool isActive}) async {
    await _api.put('/api/obituary/$id', data: {
      'isPublic': isPublic,
      'isActive': isActive,
    });
    return true;
  }

  Future<bool> delete(int id) async {
    await _api.delete('/api/obituary/$id');
    return true;
  }

  Future<bool> approveCondolence(int condolenceId) async {
    await _api.patch('/api/condolence/$condolenceId/approve');
    return true;
  }

  Future<bool> deleteCondolence(int condolenceId) async {
    await _api.delete('/api/condolence/$condolenceId');
    return true;
  }

  Future<(List<CondolenceModel>, int)> getCondolences({
    int? obituaryId,
    bool? isApproved,
    int pageNumber = 1,
    int pageSize = 50,
  }) async {
    final params = <String, dynamic>{
      'pageNumber': pageNumber,
      'pageSize': pageSize,
    };
    if (obituaryId != null) params['obituaryId'] = obituaryId;
    if (isApproved != null) params['isApproved'] = isApproved;

    final response = await _api.get('/api/condolence', queryParams: params);
    final data = response.data as Map<String, dynamic>;
    final items = (data['data'] as List<dynamic>)
        .map((e) => CondolenceModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final total = data['totalCount'] as int;
    return (items, total);
  }

  Future<List<Map<String, dynamic>>> getDeceased() async {
    final response = await _api.get('/api/deceased', queryParams: {
      'pageNumber': 1,
      'pageSize': 500,
    });
    final data = response.data as Map<String, dynamic>;
    return (data['data'] as List<dynamic>)
        .map((e) => e as Map<String, dynamic>)
        .toList();
  }
}

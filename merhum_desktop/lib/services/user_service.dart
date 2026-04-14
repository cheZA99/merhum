import '../models/user_model.dart';
import 'api_service.dart';

class UserService {
  final ApiService _api;
  UserService(this._api);

  Future<(List<UserModel>, int)> getAll({
    String? name,
    String? username,
    String? role,
    bool? isLocked,
    int pageNumber = 1,
    int pageSize = 10,
  }) async {
    final params = <String, dynamic>{
      'pageNumber': pageNumber,
      'pageSize': pageSize,
    };
    if (name != null && name.isNotEmpty) params['name'] = name;
    if (username != null && username.isNotEmpty) params['username'] = username;
    if (role != null) params['role'] = role;
    if (isLocked != null) params['isLocked'] = isLocked;

    final response = await _api.get('/api/korisnici', queryParams: params);
    final data = response.data as Map<String, dynamic>;
    final items = (data['data'] as List<dynamic>)
        .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final total = data['totalCount'] as int;
    return (items, total);
  }

  Future<UserModel> getById(String id) async {
    final response = await _api.get('/api/korisnici/$id');
    final data = response.data as Map<String, dynamic>;
    return UserModel.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<bool> create(Map<String, dynamic> data) async {
    await _api.post('/api/auth/register-admin', data: data);
    return true;
  }

  Future<bool> update(String id, Map<String, dynamic> data) async {
    await _api.put('/api/korisnici/$id', data: data);
    return true;
  }

  Future<bool> toggleLock(String id) async {
    await _api.put('/api/korisnici/$id/lock');
    return true;
  }

  Future<bool> changeRole(String id, String role) async {
    await _api.put('/api/korisnici/$id/role', data: {'role': role});
    return true;
  }

  Future<bool> resetPassword(String id) async {
    await _api.put('/api/korisnici/$id/reset-password');
    return true;
  }

  Future<List<Map<String, dynamic>>> getCities() async {
    final response = await _api.get('/api/referencedata/cities');
    final data = response.data;
    if (data is List) return data.cast<Map<String, dynamic>>();
    return [];
  }
}

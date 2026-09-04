import '../models/grave_site_model.dart';
import 'api_service.dart';

class GraveSiteService {
  static Future<GraveSiteModel> getById(int id) async {
    final res = await ApiService.get('/api/gravesite/$id');
    final data = res.data as Map<String, dynamic>;
    final body = data['data'] as Map<String, dynamic>? ?? data;
    return GraveSiteModel.fromJson(body);
  }
}

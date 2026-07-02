import '../models/deceased_model.dart';
import '../models/status_history_model.dart';
import 'api_service.dart';

class DeceasedService {
  static Future<List<DeceasedModel>> getMyDeceased() async {
    final res = await ApiService.get('/api/deceased/my', queryParams: {'pageSize': 100});
    final data = res.data as Map<String, dynamic>;
    final items = (data['data'] as List? ?? []);
    return items.map((e) => DeceasedModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<DeceasedModel?> getById(int id) async {
    final res = await ApiService.get('/api/deceased/$id');
    return DeceasedModel.fromJson(res.data as Map<String, dynamic>);
  }

  static Future<DeceasedModel> create(Map<String, dynamic> body) async {
    final res = await ApiService.post('/api/deceased', body);
    return DeceasedModel.fromJson(res.data as Map<String, dynamic>);
  }

  static Future<List<StatusHistoryModel>> getStatusHistory(int id) async {
    final res = await ApiService.get('/api/deceased/$id/status-history');
    final list = res.data as List? ?? [];
    return list.map((e) => StatusHistoryModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<List<Map<String, dynamic>>> getCities() async {
    final res = await ApiService.get('/api/referencedata/cities');
    return (res.data as List? ?? []).cast<Map<String, dynamic>>();
  }
}

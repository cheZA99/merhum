import '../models/obituary_model.dart';
import '../models/condolence_model.dart';
import 'api_service.dart';

class ObituaryService {
  static Future<List<ObituaryModel>> search(String? query, {int page = 1, int pageSize = 20}) async {
    final res = await ApiService.get('/api/smrtovnice', queryParams: {
      if (query != null && query.isNotEmpty) 'search': query,
      'pageNumber': page,
      'pageSize': pageSize,
    });
    final data = res.data as Map<String, dynamic>;
    final items = (data['items'] as List? ?? []);
    return items.map((e) => ObituaryModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<ObituaryModel?> getBySlug(String slug) async {
    final res = await ApiService.get('/api/smrtovnice/$slug');
    return ObituaryModel.fromJson(res.data as Map<String, dynamic>);
  }

  static Future<List<CondolenceModel>> getCondolences(String slug) async {
    final res = await ApiService.get('/api/smrtovnice/$slug/kondolencije');
    final list = res.data as List? ?? [];
    return list.map((e) => CondolenceModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<void> addCondolence(String slug, String authorName, String text) async {
    await ApiService.post('/api/smrtovnice/$slug/kondolencije', {
      'authorName': authorName,
      'text': text,
    });
  }

  static Future<ObituaryModel> createObituary(int deceasedId, bool isPublic) async {
    final res = await ApiService.post('/api/smrtovnice', {
      'deceasedId': deceasedId,
      'isPublic': isPublic,
    });
    return ObituaryModel.fromJson(res.data as Map<String, dynamic>);
  }

  static Future<ObituaryModel?> getByDeceasedId(int deceasedId) async {
    try {
      final res = await ApiService.get('/api/smrtovnice', queryParams: {
        'deceasedId': deceasedId,
        'pageSize': 1,
      });
      final data = res.data as Map<String, dynamic>;
      final items = (data['items'] as List? ?? []);
      if (items.isEmpty) return null;
      return ObituaryModel.fromJson(items.first as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> getUpcomingFunerals({int? cityId}) async {
    final res = await ApiService.get('/api/termini', queryParams: {
      'upcoming': true,
      if (cityId != null) 'cityId': cityId,
      'pageSize': 50,
    });
    final data = res.data;
    if (data is Map) {
      return ((data['items'] as List?) ?? []).cast<Map<String, dynamic>>();
    }
    return (data as List? ?? []).cast<Map<String, dynamic>>();
  }
}

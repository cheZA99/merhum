import '../models/obituary_model.dart';
import 'api_service.dart';

class ObituaryService {
  static Future<List<ObituaryModel>> search(String? query, {int page = 1, int pageSize = 20}) async {
    final res = await ApiService.get('/api/obituary/public', queryParams: {
      if (query != null && query.isNotEmpty) 'search': query,
      'pageNumber': page,
      'pageSize': pageSize,
    });
    final data = res.data as Map<String, dynamic>;
    final items = (data['data'] as List? ?? []);
    return items.map((e) => ObituaryModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<ObituaryModel?> getBySlug(String slug) async {
    final res = await ApiService.get('/api/obituary/slug/$slug');
    final body = res.data as Map<String, dynamic>;
    return ObituaryModel.fromJson(body['data'] as Map<String, dynamic>);
  }

  static Future<void> addCondolence(int obituaryId, String authorName, String text) async {
    await ApiService.post('/api/condolence', {
      'obituaryId': obituaryId,
      'authorName': authorName,
      'text': text,
    });
  }

  static Future<ObituaryModel> createObituary(int deceasedId, bool isPublic) async {
    final res = await ApiService.post('/api/obituary', {
      'deceasedId': deceasedId,
      'isPublic': isPublic,
    });
    final body = res.data as Map<String, dynamic>;
    return ObituaryModel.fromJson(body['data'] as Map<String, dynamic>);
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
    final res = await ApiService.get('/api/appointment/upcoming', queryParams: {
      if (cityId != null) 'cityId': cityId,
    });
    final data = res.data;
    if (data is Map) {
      return ((data['data'] as List?) ?? []).cast<Map<String, dynamic>>();
    }
    return (data as List? ?? []).cast<Map<String, dynamic>>();
  }
}

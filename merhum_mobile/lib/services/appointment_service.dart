import '../models/appointment_model.dart';
import 'api_service.dart';

class AppointmentService {
  static Future<List<AppointmentModel>> getMyAppointments({bool upcoming = false}) async {
    // no imam-user link yet, so this returns all upcoming; screen splits them client-side
    final res = await ApiService.get('/api/appointment/upcoming');
    final data = res.data;
    List items;
    if (data is Map) {
      items = (data['data'] as List? ?? []);
    } else {
      items = (data as List? ?? []);
    }
    return items.map((e) => AppointmentModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<AppointmentModel?> getByDeceasedId(int deceasedId) async {
    try {
      final res = await ApiService.get('/api/termini', queryParams: {'deceasedId': deceasedId, 'pageSize': 1});
      final data = res.data;
      List items;
      if (data is Map) {
        items = (data['items'] as List? ?? []);
      } else {
        items = (data as List? ?? []);
      }
      if (items.isEmpty) return null;
      return AppointmentModel.fromJson(items.first as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  static Future<AppointmentModel> create(Map<String, dynamic> body) async {
    final res = await ApiService.post('/api/termini', body);
    return AppointmentModel.fromJson(res.data as Map<String, dynamic>);
  }

  static Future<List<Map<String, dynamic>>> getMosques() async {
    final res = await ApiService.get('/api/dzamije', queryParams: {'pageSize': 200});
    final data = res.data;
    if (data is Map) return ((data['items'] as List?) ?? []).cast<Map<String, dynamic>>();
    return (data as List? ?? []).cast<Map<String, dynamic>>();
  }

  static Future<List<Map<String, dynamic>>> getImamsByMosque(int mosqueId) async {
    final res = await ApiService.get('/api/imami', queryParams: {'mosqueId': mosqueId, 'pageSize': 100});
    final data = res.data;
    if (data is Map) return ((data['items'] as List?) ?? []).cast<Map<String, dynamic>>();
    return (data as List? ?? []).cast<Map<String, dynamic>>();
  }

  static Future<List<Map<String, dynamic>>> getCemeteries() async {
    final res = await ApiService.get('/api/groblja', queryParams: {'pageSize': 200});
    final data = res.data;
    if (data is Map) return ((data['items'] as List?) ?? []).cast<Map<String, dynamic>>();
    return (data as List? ?? []).cast<Map<String, dynamic>>();
  }

  static Future<List<Map<String, dynamic>>> getAvailableGraveSites(int cemeteryId) async {
    final res = await ApiService.get('/api/mezarska-mjesta', queryParams: {
      'cemeteryId': cemeteryId,
      'status': 'Available',
      'pageSize': 200,
    });
    final data = res.data;
    if (data is Map) return ((data['items'] as List?) ?? []).cast<Map<String, dynamic>>();
    return (data as List? ?? []).cast<Map<String, dynamic>>();
  }
}

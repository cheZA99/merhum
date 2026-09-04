import '../models/appointment_model.dart';
import 'api_service.dart';

class AppointmentService {
  static Future<List<AppointmentModel>> getMyAppointments({bool upcoming = false}) async {
    final res = await ApiService.get('/api/Appointment', queryParams: {
      'pageSize': 200,
      if (upcoming) 'status': 'Scheduled',
      if (upcoming) 'dateFrom': DateTime.now().toIso8601String(),
    });
    final data = res.data;
    final items = data is Map ? (data['data'] as List? ?? []) : (data as List? ?? []);
    return items.map((e) => AppointmentModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<AppointmentModel?> getByDeceasedId(int deceasedId) async {
    final res = await ApiService.get('/api/Appointment', queryParams: {'deceasedId': deceasedId, 'pageSize': 1});
    final data = res.data;
    List items;
    if (data is Map) {
      items = (data['data'] as List? ?? []);
    } else {
      items = (data as List? ?? []);
    }
    if (items.isEmpty) return null;
    return AppointmentModel.fromJson(items.first as Map<String, dynamic>);
  }

  static Future<AppointmentModel> create(Map<String, dynamic> body) async {
    final res = await ApiService.post('/api/Appointment', body);
    final data = res.data;
    final obj = data is Map<String, dynamic> && data['data'] is Map
        ? data['data'] as Map<String, dynamic>
        : data as Map<String, dynamic>;
    return AppointmentModel.fromJson(obj);
  }

  static Future<List<Map<String, dynamic>>> getMosques() async {
    final res = await ApiService.get('/api/Mosque', queryParams: {'pageSize': 200});
    final data = res.data;
    if (data is Map) return ((data['data'] as List?) ?? []).cast<Map<String, dynamic>>();
    return (data as List? ?? []).cast<Map<String, dynamic>>();
  }

  static Future<List<Map<String, dynamic>>> getImamsByMosque(int mosqueId) async {
    final res = await ApiService.get('/api/Imam', queryParams: {'mosqueId': mosqueId, 'pageSize': 100});
    final data = res.data;
    if (data is Map) return ((data['data'] as List?) ?? []).cast<Map<String, dynamic>>();
    return (data as List? ?? []).cast<Map<String, dynamic>>();
  }

  static Future<List<Map<String, dynamic>>> getCemeteries() async {
    final res = await ApiService.get('/api/Cemetery', queryParams: {'pageSize': 200});
    final data = res.data;
    if (data is Map) return ((data['data'] as List?) ?? []).cast<Map<String, dynamic>>();
    return (data as List? ?? []).cast<Map<String, dynamic>>();
  }

  static Future<List<Map<String, dynamic>>> getAvailableGraveSites(int cemeteryId) async {
    final res = await ApiService.get('/api/GraveSite', queryParams: {
      'cemeteryId': cemeteryId,
      'status': 'Available',
      'pageSize': 200,
    });
    final data = res.data;
    if (data is Map) return ((data['data'] as List?) ?? []).cast<Map<String, dynamic>>();
    return (data as List? ?? []).cast<Map<String, dynamic>>();
  }
}

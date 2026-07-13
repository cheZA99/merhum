import 'api_service.dart';
import '../models/notification_model.dart';

class NotificationService {
  static Future<List<NotificationModel>> getNotifications() async {
    final res = await ApiService.get('/api/notifikacije', queryParams: {'pageSize': 50});
    final body = res.data as Map<String, dynamic>;
    final data = body['data'] as List? ?? [];
    return data.map((e) => NotificationModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<int> getUnreadCount() async {
    final res = await ApiService.get('/api/notifikacije/nepregledano');
    final body = res.data as Map<String, dynamic>;
    return body['data'] as int? ?? 0;
  }

  static Future<void> markRead(int id) async {
    await ApiService.put('/api/notifikacije/$id/procitano', null);
  }

  static Future<void> markAllRead() async {
    await ApiService.put('/api/notifikacije/procitano-sve', null);
  }
}

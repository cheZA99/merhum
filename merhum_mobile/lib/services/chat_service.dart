import '../models/chat_history_item_model.dart';
import 'api_service.dart';

class ChatService {
  static Future<String> sendMessage(String message) async {
    final res = await ApiService.post('/api/chat/message', {'message': message});
    final body = res.data as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw Exception(body['message'] as String? ?? 'Greška pri slanju poruke.');
    }
    return data['response'] as String? ?? '';
  }

  static Future<List<ChatHistoryItemModel>> getHistory({int page = 1, int pageSize = 50}) async {
    final res = await ApiService.get('/api/chat/history', queryParams: {
      'pageNumber': page,
      'pageSize': pageSize,
    });
    final body = res.data as Map<String, dynamic>;
    final list = (body['data'] as List?) ?? [];
    return list
        .map((e) => ChatHistoryItemModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> clearHistory() async {
    await ApiService.delete('/api/chat/history');
  }
}

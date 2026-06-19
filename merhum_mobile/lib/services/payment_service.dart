import 'api_service.dart';

class PaymentService {
  static Future<Map<String, dynamic>> initiatePayment(int serviceOrderId) async {
    final res = await ApiService.post('/api/payments/initiate', {'serviceOrderId': serviceOrderId});
    final body = res.data as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw Exception(body['message'] as String? ?? 'Greška pri pokretanju plaćanja.');
    }
    return data;
  }

  static Future<bool> capturePayment(String paypalOrderId) async {
    final res = await ApiService.post('/api/payments/capture', {'paypalOrderId': paypalOrderId});
    final body = res.data as Map<String, dynamic>;
    return body['success'] as bool? ?? false;
  }

  static Future<String> getPaymentStatus(int serviceOrderId) async {
    final res = await ApiService.get('/api/payments/order/$serviceOrderId');
    final body = res.data as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>?;
    return data?['status'] as String? ?? 'None';
  }
}

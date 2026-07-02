import '../models/service_order_model.dart';
import 'api_service.dart';

class ServiceOrderService {
  static Future<List<ServiceOrderModel>> getByDeceasedId(int deceasedId) async {
    final res = await ApiService.get('/api/ServiceOrder', queryParams: {'deceasedId': deceasedId, 'pageSize': 100});
    final body = res.data as Map<String, dynamic>;
    final items = (body['data'] as List? ?? []);
    return items.map((e) => ServiceOrderModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<List<ServiceOrderModel>> getMyOrders({String? status}) async {
    final res = await ApiService.get('/api/ServiceOrder', queryParams: {
      if (status != null && status != 'Sve') 'status': status,
      'pageSize': 100,
    });
    final body = res.data as Map<String, dynamic>;
    final items = (body['data'] as List? ?? []);
    return items.map((e) => ServiceOrderModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<ServiceOrderModel> create(Map<String, dynamic> body) async {
    final res = await ApiService.post('/api/ServiceOrder', body);
    final responseBody = res.data as Map<String, dynamic>;
    return ServiceOrderModel.fromJson(responseBody['data'] as Map<String, dynamic>);
  }

  static Future<void> updateStatus(int id, String status) async {
    await ApiService.patch('/api/ServiceOrder/$id/status', {'status': status});
  }

  static Future<List<Map<String, dynamic>>> getFuneralHomes() async {
    final res = await ApiService.get('/api/FuneralHome', queryParams: {'pageSize': 200});
    final body = res.data as Map<String, dynamic>;
    return ((body['data'] as List?) ?? []).cast<Map<String, dynamic>>();
  }

  static Future<List<Map<String, dynamic>>> getServiceTypes() async {
    final res = await ApiService.get('/api/ReferenceData/service-types');
    return (res.data as List? ?? []).cast<Map<String, dynamic>>();
  }
}

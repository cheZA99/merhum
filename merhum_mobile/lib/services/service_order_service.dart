import '../models/service_order_model.dart';
import 'api_service.dart';

class ServiceOrderService {
  static Future<List<ServiceOrderModel>> getByDeceasedId(int deceasedId) async {
    final res = await ApiService.get('/api/narudzbe', queryParams: {'deceasedId': deceasedId, 'pageSize': 100});
    final data = res.data;
    List items;
    if (data is Map) {
      items = (data['items'] as List? ?? []);
    } else {
      items = (data as List? ?? []);
    }
    return items.map((e) => ServiceOrderModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<List<ServiceOrderModel>> getMyOrders({String? status}) async {
    final res = await ApiService.get('/api/narudzbe', queryParams: {
      'myOnly': true,
      if (status != null && status != 'Sve') 'status': status,
      'pageSize': 100,
    });
    final data = res.data;
    List items;
    if (data is Map) {
      items = (data['items'] as List? ?? []);
    } else {
      items = (data as List? ?? []);
    }
    return items.map((e) => ServiceOrderModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<ServiceOrderModel> create(Map<String, dynamic> body) async {
    final res = await ApiService.post('/api/narudzbe', body);
    return ServiceOrderModel.fromJson(res.data as Map<String, dynamic>);
  }

  static Future<void> updateStatus(int id, String status) async {
    await ApiService.patch('/api/narudzbe/$id/status', {'status': status});
  }

  static Future<List<Map<String, dynamic>>> getFuneralHomes() async {
    final res = await ApiService.get('/api/pogrebna-preduzeca', queryParams: {'pageSize': 200});
    final data = res.data;
    if (data is Map) return ((data['items'] as List?) ?? []).cast<Map<String, dynamic>>();
    return (data as List? ?? []).cast<Map<String, dynamic>>();
  }

  static Future<List<Map<String, dynamic>>> getServiceTypes() async {
    final res = await ApiService.get('/api/referencedata/service-types');
    return (res.data as List? ?? []).cast<Map<String, dynamic>>();
  }
}

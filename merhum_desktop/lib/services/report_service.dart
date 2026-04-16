import 'api_service.dart';

class ReportService {
  final ApiService _api;
  ReportService(this._api);

  Future<Map<String, dynamic>> getBurialReport({int? year}) async {
    final params = <String, dynamic>{};
    if (year != null) params['year'] = year;
    final response = await _api.get('/api/report/burial', queryParams: params);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getCemeteryCapacityReport() async {
    final response = await _api.get('/api/report/cemetery-capacity');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getServicesReport({int? year}) async {
    final params = <String, dynamic>{};
    if (year != null) params['year'] = year;
    final response = await _api.get('/api/report/services', queryParams: params);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getObituariesStatsReport() async {
    final response = await _api.get('/api/report/obituaries-stats');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getFinancialReport({int? year}) async {
    final params = <String, dynamic>{};
    if (year != null) params['year'] = year;
    final response = await _api.get('/api/report/financial', queryParams: params);
    return response.data as Map<String, dynamic>;
  }
}

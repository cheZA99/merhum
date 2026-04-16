import 'package:flutter/foundation.dart';
import '../services/report_service.dart';

class ReportProvider extends ChangeNotifier {
  final ReportService _service;
  ReportProvider(this._service);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Map<String, dynamic>? burialData;
  Map<String, dynamic>? cemeteryCapacityData;
  Map<String, dynamic>? servicesData;
  Map<String, dynamic>? obituariesStatsData;
  Map<String, dynamic>? financialData;

  int selectedYear = DateTime.now().year;

  Future<void> loadBurialReport() => _load(
        () async => burialData = await _service.getBurialReport(year: selectedYear),
      );

  Future<void> loadCemeteryCapacityReport() => _load(
        () async => cemeteryCapacityData = await _service.getCemeteryCapacityReport(),
      );

  Future<void> loadServicesReport() => _load(
        () async => servicesData = await _service.getServicesReport(year: selectedYear),
      );

  Future<void> loadObituariesStatsReport() => _load(
        () async => obituariesStatsData = await _service.getObituariesStatsReport(),
      );

  Future<void> loadFinancialReport() => _load(
        () async => financialData = await _service.getFinancialReport(year: selectedYear),
      );

  Future<void> _load(Future<void> Function() fn) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await fn();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setYear(int year) {
    selectedYear = year;
    notifyListeners();
  }
}

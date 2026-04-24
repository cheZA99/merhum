import 'package:flutter/material.dart';
import '../models/appointment_model.dart';
import '../services/appointment_service.dart';

class AppointmentProvider extends ChangeNotifier {
  List<AppointmentModel> _appointments = [];
  AppointmentModel? _selectedAppointment;
  List<Map<String, dynamic>> _mosques = [];
  List<Map<String, dynamic>> _imams = [];
  List<Map<String, dynamic>> _cemeteries = [];
  List<Map<String, dynamic>> _graveSites = [];
  bool _isLoading = false;

  List<AppointmentModel> get appointments => _appointments;
  AppointmentModel? get selectedAppointment => _selectedAppointment;
  List<Map<String, dynamic>> get mosques => _mosques;
  List<Map<String, dynamic>> get imams => _imams;
  List<Map<String, dynamic>> get cemeteries => _cemeteries;
  List<Map<String, dynamic>> get graveSites => _graveSites;
  bool get isLoading => _isLoading;

  Future<void> loadMyAppointments({bool upcoming = false}) async {
    _isLoading = true;
    notifyListeners();
    try {
      _appointments = await AppointmentService.getMyAppointments(upcoming: upcoming);
    } catch (_) {
      _appointments = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadForDeceased(int deceasedId) async {
    try {
      _selectedAppointment = await AppointmentService.getByDeceasedId(deceasedId);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> loadMosques() async {
    if (_mosques.isNotEmpty) return;
    try {
      _mosques = await AppointmentService.getMosques();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> loadImamsByMosque(int mosqueId) async {
    try {
      _imams = await AppointmentService.getImamsByMosque(mosqueId);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> loadCemeteries() async {
    if (_cemeteries.isNotEmpty) return;
    try {
      _cemeteries = await AppointmentService.getCemeteries();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> loadGraveSites(int cemeteryId) async {
    try {
      _graveSites = await AppointmentService.getAvailableGraveSites(cemeteryId);
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> createAppointment(Map<String, dynamic> body) async {
    _isLoading = true;
    notifyListeners();
    try {
      final result = await AppointmentService.create(body);
      _selectedAppointment = result;
      return true;
    } catch (_) {
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

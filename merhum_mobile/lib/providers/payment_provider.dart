import 'package:flutter/material.dart';
import '../services/payment_service.dart';
import '../utils/api_error.dart';

class PaymentProvider extends ChangeNotifier {
  final Map<int, String> _statusByOrder = {};
  String? _error;

  String statusFor(int serviceOrderId) => _statusByOrder[serviceOrderId] ?? 'None';
  bool isPaid(int serviceOrderId) => statusFor(serviceOrderId) == 'Completed';
  String? get error => _error;

  Future<void> loadStatuses(List<int> serviceOrderIds) async {
    await Future.wait(serviceOrderIds.map(_loadStatus));
    notifyListeners();
  }

  Future<void> _loadStatus(int serviceOrderId) async {
    try {
      _statusByOrder[serviceOrderId] = await PaymentService.getPaymentStatus(serviceOrderId);
    } catch (e) {
      _statusByOrder[serviceOrderId] = 'None';
      _error = parseApiError(e);
    }
  }

  Future<Map<String, dynamic>?> initiate(int serviceOrderId) async {
    try {
      return await PaymentService.initiatePayment(serviceOrderId);
    } catch (e) {
      _error = parseApiError(e);
      notifyListeners();
      return null;
    }
  }

  Future<bool> capture(String paypalOrderId, int serviceOrderId) async {
    try {
      final ok = await PaymentService.capturePayment(paypalOrderId);
      if (ok) {
        _statusByOrder[serviceOrderId] = 'Completed';
        notifyListeners();
      }
      return ok;
    } catch (e) {
      _error = parseApiError(e);
      notifyListeners();
      return false;
    }
  }

  Future<String?> refund(int serviceOrderId) async {
    try {
      await PaymentService.refundPayment(serviceOrderId);
      _statusByOrder[serviceOrderId] = 'Refunded';
      notifyListeners();
      return null;
    } catch (e) {
      final message = parseApiError(e, 'Greška pri povratu sredstava.');
      _error = message;
      notifyListeners();
      return message;
    }
  }
}

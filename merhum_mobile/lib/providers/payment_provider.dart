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

  // releases the pending payment so the order does not stay blocked after a cancelled PayPal session
  Future<void> cancel(int serviceOrderId) async {
    try {
      await PaymentService.cancelPayment(serviceOrderId);
      _statusByOrder[serviceOrderId] = 'None';
      notifyListeners();
    } catch (e) {
      _error = parseApiError(e);
      notifyListeners();
    }
  }
}

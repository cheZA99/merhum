import 'package:flutter/material.dart';
import '../services/payment_service.dart';

class PaymentProvider extends ChangeNotifier {
  final Map<int, String> _statusByOrder = {};

  String statusFor(int serviceOrderId) => _statusByOrder[serviceOrderId] ?? 'None';
  bool isPaid(int serviceOrderId) => statusFor(serviceOrderId) == 'Completed';

  Future<void> loadStatuses(List<int> serviceOrderIds) async {
    await Future.wait(serviceOrderIds.map(_loadStatus));
    notifyListeners();
  }

  Future<void> _loadStatus(int serviceOrderId) async {
    try {
      _statusByOrder[serviceOrderId] = await PaymentService.getPaymentStatus(serviceOrderId);
    } catch (_) {
      _statusByOrder[serviceOrderId] = 'None';
    }
  }

  Future<Map<String, dynamic>?> initiate(int serviceOrderId) async {
    try {
      return await PaymentService.initiatePayment(serviceOrderId);
    } catch (_) {
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
    } catch (_) {
      return false;
    }
  }
}

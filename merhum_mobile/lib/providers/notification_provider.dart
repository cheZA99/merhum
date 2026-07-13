import 'dart:async';
import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  List<NotificationModel> _items = [];
  int _unreadCount = 0;
  bool _loading = false;
  Timer? _timer;

  List<NotificationModel> get items => _items;
  int get unreadCount => _unreadCount;
  bool get loading => _loading;

  void startPolling() {
    refreshUnreadCount();
    _timer ??= Timer.periodic(const Duration(seconds: 25), (_) => refreshUnreadCount());
  }

  void stopPolling() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> refreshUnreadCount() async {
    try {
      _unreadCount = await NotificationService.getUnreadCount();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> loadNotifications() async {
    _loading = true;
    notifyListeners();
    try {
      _items = await NotificationService.getNotifications();
      _unreadCount = _items.where((n) => !n.isRead).length;
    } catch (_) {
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> markRead(int id) async {
    final idx = _items.indexWhere((n) => n.id == id);
    if (idx == -1 || _items[idx].isRead) return;
    try {
      await NotificationService.markRead(id);
      _items[idx] = _items[idx].markedRead();
      if (_unreadCount > 0) _unreadCount--;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> markAllRead() async {
    try {
      await NotificationService.markAllRead();
      _items = _items.map((n) => n.markedRead()).toList();
      _unreadCount = 0;
      notifyListeners();
    } catch (_) {}
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

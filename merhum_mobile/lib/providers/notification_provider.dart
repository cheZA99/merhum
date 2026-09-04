import 'dart:async';
import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';
import '../utils/api_error.dart';

class NotificationProvider extends ChangeNotifier {
  List<NotificationModel> _items = [];
  int _unreadCount = 0;
  bool _loading = false;
  String? _error;
  Timer? _timer;

  List<NotificationModel> get items => _items;
  int get unreadCount => _unreadCount;
  bool get loading => _loading;
  String? get error => _error;

  void startPolling() {
    refresh();
    _timer ??= Timer.periodic(const Duration(seconds: 25), (_) => refresh());
  }

  void stopPolling() {
    _timer?.cancel();
    _timer = null;
  }

  // silent refresh of both list and badge, so an open list cannot show a stale state
  Future<void> refresh() async {
    try {
      _items = await NotificationService.getNotifications();
      _unreadCount = _items.where((n) => !n.isRead).length;
      _error = null;
    } catch (e) {
      _error = parseApiError(e);
    }
    notifyListeners();
  }

  Future<void> loadNotifications() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _items = await NotificationService.getNotifications();
      _unreadCount = _items.where((n) => !n.isRead).length;
    } catch (e) {
      _error = parseApiError(e);
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
    } catch (e) {
      _error = parseApiError(e);
      notifyListeners();
    }
  }

  Future<void> markAllRead() async {
    try {
      await NotificationService.markAllRead();
      _items = _items.map((n) => n.markedRead()).toList();
      _unreadCount = 0;
      notifyListeners();
    } catch (e) {
      _error = parseApiError(e);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

import 'package:flutter/material.dart';
import '../models/chat_message_model.dart';
import '../services/chat_service.dart';

class ChatProvider extends ChangeNotifier {
  final List<ChatMessageModel> _messages = [];
  bool _isSending = false;
  bool _isLoadingHistory = false;
  String? _error;

  List<ChatMessageModel> get messages => List.unmodifiable(_messages);
  bool get isSending => _isSending;
  bool get isLoadingHistory => _isLoadingHistory;
  String? get error => _error;

  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isSending) return;

    _error = null;
    _messages.add(ChatMessageModel(
      text: trimmed,
      isUser: true,
      timestamp: DateTime.now(),
    ));
    _isSending = true;
    notifyListeners();

    try {
      final response = await ChatService.sendMessage(trimmed);
      _messages.add(ChatMessageModel(
        text: response,
        isUser: false,
        timestamp: DateTime.now(),
      ));
    } catch (e) {
      _error = e.toString();
      _messages.add(ChatMessageModel(
        text: 'Žao mi je, došlo je do greške pri obradi Vaše poruke. Pokušajte ponovo.',
        isUser: false,
        timestamp: DateTime.now(),
        isError: true,
      ));
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  Future<void> loadHistory() async {
    if (_isLoadingHistory) return;
    _isLoadingHistory = true;
    _error = null;
    notifyListeners();

    try {
      final history = await ChatService.getHistory();
      // History is returned newest-first; reverse to display oldest-first
      final ordered = history.reversed.toList();
      _messages.clear();
      for (final item in ordered) {
        _messages.add(ChatMessageModel(
          id: item.id,
          text: item.message,
          isUser: true,
          timestamp: item.createdAt,
        ));
        _messages.add(ChatMessageModel(
          id: item.id,
          text: item.response,
          isUser: false,
          timestamp: item.createdAt,
        ));
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingHistory = false;
      notifyListeners();
    }
  }

  Future<void> clearChat() async {
    try {
      await ChatService.clearHistory();
      _messages.clear();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      notifyListeners();
    }
  }

  void retryLast() {
    if (_messages.isEmpty) return;
    // Find last user message and resend
    for (int i = _messages.length - 1; i >= 0; i--) {
      if (_messages[i].isUser) {
        final text = _messages[i].text;
        // Remove trailing error message(s)
        while (_messages.length > i + 1) {
          _messages.removeLast();
        }
        _messages.removeAt(i);
        notifyListeners();
        sendMessage(text);
        return;
      }
    }
  }
}

class ChatMessageModel {
  final int? id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isError;

  ChatMessageModel({
    this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isError = false,
  });
}

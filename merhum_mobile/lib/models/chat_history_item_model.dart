class ChatHistoryItemModel {
  final int id;
  final String message;
  final String response;
  final DateTime createdAt;

  ChatHistoryItemModel({
    required this.id,
    required this.message,
    required this.response,
    required this.createdAt,
  });

  factory ChatHistoryItemModel.fromJson(Map<String, dynamic> json) => ChatHistoryItemModel(
        id: json['id'] as int,
        message: json['message'] as String? ?? '',
        response: json['response'] as String? ?? '',
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

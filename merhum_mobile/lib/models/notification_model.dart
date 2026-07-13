class NotificationModel {
  final int id;
  final String title;
  final String message;
  final bool isRead;
  final DateTime? createdAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.isRead,
    this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> j) => NotificationModel(
        id: j['id'] as int,
        title: j['title'] as String? ?? '',
        message: j['message'] as String? ?? '',
        isRead: j['isRead'] as bool? ?? false,
        createdAt: j['createdAt'] != null
            ? DateTime.tryParse(j['createdAt'] as String)?.toLocal()
            : null,
      );

  NotificationModel markedRead() => NotificationModel(
        id: id,
        title: title,
        message: message,
        isRead: true,
        createdAt: createdAt,
      );
}

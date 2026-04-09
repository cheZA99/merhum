class StatusHistoryModel {
  final int id;
  final int deceasedId;
  final int statusId;
  final String statusName;
  final String? note;
  final DateTime changedAt;
  final String changedByUsername;

  const StatusHistoryModel({
    required this.id,
    required this.deceasedId,
    required this.statusId,
    required this.statusName,
    this.note,
    required this.changedAt,
    required this.changedByUsername,
  });

  factory StatusHistoryModel.fromJson(Map<String, dynamic> json) {
    return StatusHistoryModel(
      id: json['id'] as int,
      deceasedId: json['deceasedId'] as int,
      statusId: json['statusId'] as int,
      statusName: json['statusName'] as String,
      note: json['note'] as String?,
      changedAt: DateTime.parse(json['changedAt'] as String),
      changedByUsername: json['changedByUsername'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'deceasedId': deceasedId,
        'statusId': statusId,
        'statusName': statusName,
        'note': note,
        'changedAt': changedAt.toIso8601String(),
        'changedByUsername': changedByUsername,
      };
}

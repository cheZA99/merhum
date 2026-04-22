class StatusHistoryModel {
  final int id;
  final int statusId;
  final String statusName;
  final DateTime changedAt;
  final String? note;

  StatusHistoryModel({
    required this.id,
    required this.statusId,
    required this.statusName,
    required this.changedAt,
    this.note,
  });

  factory StatusHistoryModel.fromJson(Map<String, dynamic> j) => StatusHistoryModel(
        id: j['id'] as int,
        statusId: j['statusId'] as int,
        statusName: j['statusName'] as String? ?? '',
        changedAt: DateTime.parse(j['changedAt'] as String),
        note: j['note'] as String?,
      );
}

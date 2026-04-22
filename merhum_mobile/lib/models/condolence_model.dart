class CondolenceModel {
  final int id;
  final String authorName;
  final String text;
  final bool isApproved;
  final DateTime submittedAt;

  CondolenceModel({
    required this.id,
    required this.authorName,
    required this.text,
    required this.isApproved,
    required this.submittedAt,
  });

  factory CondolenceModel.fromJson(Map<String, dynamic> j) => CondolenceModel(
        id: j['id'] as int,
        authorName: j['authorName'] as String? ?? '',
        text: j['text'] as String? ?? '',
        isApproved: j['isApproved'] as bool? ?? false,
        submittedAt: DateTime.parse(j['submittedAt'] as String),
      );
}

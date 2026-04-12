class CondolenceModel {
  final int id;
  final int obituaryId;
  final String authorName;
  final String text;
  final bool isApproved;
  final DateTime createdAt;

  const CondolenceModel({
    required this.id,
    required this.obituaryId,
    required this.authorName,
    required this.text,
    required this.isApproved,
    required this.createdAt,
  });

  factory CondolenceModel.fromJson(Map<String, dynamic> json) {
    return CondolenceModel(
      id: json['id'] as int,
      obituaryId: json['obituaryId'] as int? ?? 0,
      authorName: json['authorName'] as String? ?? '',
      text: json['text'] as String? ?? '',
      isApproved: json['isApproved'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class ObituaryModel {
  final int id;
  final int deceasedId;
  final String deceasedFullName;
  final String? deceasedPhotoUrl;
  final String? deceasedDateOfDeath;
  final String uniqueSlug;
  final String? qrCodeUrl;
  final int viewCount;
  final bool isPublic;
  final bool isActive;
  final DateTime createdAt;
  final String? createdByUsername;
  final int condolenceCount;
  final int approvedCondolenceCount;
  final List<CondolenceModel> condolences;

  const ObituaryModel({
    required this.id,
    required this.deceasedId,
    required this.deceasedFullName,
    this.deceasedPhotoUrl,
    this.deceasedDateOfDeath,
    required this.uniqueSlug,
    this.qrCodeUrl,
    required this.viewCount,
    required this.isPublic,
    required this.isActive,
    required this.createdAt,
    this.createdByUsername,
    required this.condolenceCount,
    required this.approvedCondolenceCount,
    required this.condolences,
  });

  factory ObituaryModel.fromJson(Map<String, dynamic> json) {
    return ObituaryModel(
      id: json['id'] as int,
      deceasedId: json['deceasedId'] as int,
      deceasedFullName: json['deceasedFullName'] as String? ?? '',
      deceasedPhotoUrl: json['deceasedPhotoUrl'] as String?,
      deceasedDateOfDeath: json['deceasedDateOfDeath'] as String?,
      uniqueSlug: json['uniqueSlug'] as String? ?? '',
      qrCodeUrl: json['qrCodeUrl'] as String?,
      viewCount: json['viewCount'] as int? ?? 0,
      isPublic: json['isPublic'] as bool? ?? true,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      createdByUsername: json['createdByUsername'] as String?,
      condolenceCount: json['condolenceCount'] as int? ?? 0,
      approvedCondolenceCount: json['approvedCondolenceCount'] as int? ?? 0,
      condolences: (json['condolences'] as List<dynamic>? ?? [])
          .map((c) => CondolenceModel.fromJson(c as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ServiceOrderModel {
  final int id;
  final int deceasedId;
  final String deceasedFullName;
  final int funeralHomeId;
  final String funeralHomeName;
  final int serviceTypeId;
  final String serviceTypeName;
  final double price;
  final String status;
  final String? note;
  final DateTime orderedAt;
  final DateTime? completedAt;

  const ServiceOrderModel({
    required this.id,
    required this.deceasedId,
    required this.deceasedFullName,
    required this.funeralHomeId,
    required this.funeralHomeName,
    required this.serviceTypeId,
    required this.serviceTypeName,
    required this.price,
    required this.status,
    this.note,
    required this.orderedAt,
    this.completedAt,
  });

  factory ServiceOrderModel.fromJson(Map<String, dynamic> json) {
    return ServiceOrderModel(
      id: json['id'] as int,
      deceasedId: json['deceasedId'] as int,
      deceasedFullName: json['deceasedFullName'] as String? ?? '',
      funeralHomeId: json['funeralHomeId'] as int,
      funeralHomeName: json['funeralHomeName'] as String? ?? '',
      serviceTypeId: json['serviceTypeId'] as int,
      serviceTypeName: json['serviceTypeName'] as String? ?? '',
      price: (json['price'] as num).toDouble(),
      status: json['status'] as String? ?? '',
      note: json['note'] as String?,
      orderedAt: DateTime.parse(json['orderedAt'] as String),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'deceasedId': deceasedId,
        'funeralHomeId': funeralHomeId,
        'serviceTypeId': serviceTypeId,
        'price': price,
        'status': status,
        'completedAt': completedAt?.toIso8601String(),
        'note': note,
      };

  ServiceOrderModel copyWith({
    int? id,
    int? deceasedId,
    String? deceasedFullName,
    int? funeralHomeId,
    String? funeralHomeName,
    int? serviceTypeId,
    String? serviceTypeName,
    double? price,
    String? status,
    String? note,
    DateTime? orderedAt,
    DateTime? completedAt,
  }) {
    return ServiceOrderModel(
      id: id ?? this.id,
      deceasedId: deceasedId ?? this.deceasedId,
      deceasedFullName: deceasedFullName ?? this.deceasedFullName,
      funeralHomeId: funeralHomeId ?? this.funeralHomeId,
      funeralHomeName: funeralHomeName ?? this.funeralHomeName,
      serviceTypeId: serviceTypeId ?? this.serviceTypeId,
      serviceTypeName: serviceTypeName ?? this.serviceTypeName,
      price: price ?? this.price,
      status: status ?? this.status,
      note: note ?? this.note,
      orderedAt: orderedAt ?? this.orderedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}

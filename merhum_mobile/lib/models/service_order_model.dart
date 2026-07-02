class ServiceOrderModel {
  final int id;
  final int deceasedId;
  final String? deceasedFullName;
  final int? funeralHomeId;
  final String? funeralHomeName;
  final int? serviceTypeId;
  final String? serviceTypeName;
  final double price;
  final String status;
  final String? notes;
  final DateTime orderedAt;

  ServiceOrderModel({
    required this.id,
    required this.deceasedId,
    this.deceasedFullName,
    this.funeralHomeId,
    this.funeralHomeName,
    this.serviceTypeId,
    this.serviceTypeName,
    required this.price,
    required this.status,
    this.notes,
    required this.orderedAt,
  });

  factory ServiceOrderModel.fromJson(Map<String, dynamic> j) => ServiceOrderModel(
        id: j['id'] as int,
        deceasedId: j['deceasedId'] as int,
        deceasedFullName: j['deceasedFullName'] as String?,
        funeralHomeId: j['funeralHomeId'] as int?,
        funeralHomeName: j['funeralHomeName'] as String?,
        serviceTypeId: j['serviceTypeId'] as int?,
        serviceTypeName: j['serviceTypeName'] as String?,
        price: (j['price'] as num?)?.toDouble() ?? 0.0,
        status: j['status'] as String? ?? 'Ordered',
        notes: j['note'] as String?,
        orderedAt: DateTime.parse(j['orderedAt'] as String),
      );
}

class CemeteryPredictionModel {
  final int cemeteryId;
  final String cemeteryName;
  final int totalCapacity;
  final int currentOccupancy;
  final double occupancyPercentage;
  final double averageBurialsPerMonth;
  final double predictedMonthsUntilFull;
  final DateTime estimatedFullDate;
  final String confidenceLevel;

  const CemeteryPredictionModel({
    required this.cemeteryId,
    required this.cemeteryName,
    required this.totalCapacity,
    required this.currentOccupancy,
    required this.occupancyPercentage,
    required this.averageBurialsPerMonth,
    required this.predictedMonthsUntilFull,
    required this.estimatedFullDate,
    required this.confidenceLevel,
  });

  factory CemeteryPredictionModel.fromJson(Map<String, dynamic> json) {
    return CemeteryPredictionModel(
      cemeteryId: json['cemeteryId'] as int? ?? 0,
      cemeteryName: json['cemeteryName'] as String? ?? '',
      totalCapacity: json['totalCapacity'] as int? ?? 0,
      currentOccupancy: json['currentOccupancy'] as int? ?? 0,
      occupancyPercentage: (json['occupancyPercentage'] as num?)?.toDouble() ?? 0.0,
      averageBurialsPerMonth: (json['averageBurialsPerMonth'] as num?)?.toDouble() ?? 0.0,
      predictedMonthsUntilFull: (json['predictedMonthsUntilFull'] as num?)?.toDouble() ?? 0.0,
      estimatedFullDate: DateTime.tryParse(json['estimatedFullDate'] as String? ?? '') ??
          DateTime.now(),
      confidenceLevel: json['confidenceLevel'] as String? ?? 'Niska',
    );
  }
}

class ProcedureStatusModel {
  final int id;
  final String name;
  final int order;

  ProcedureStatusModel({
    required this.id,
    required this.name,
    required this.order,
  });

  factory ProcedureStatusModel.fromJson(Map<String, dynamic> j) => ProcedureStatusModel(
        id: j['id'] as int,
        name: j['name'] as String? ?? '',
        order: j['order'] as int? ?? 0,
      );

  static const List<String> phases = [
    'Prijavljen',
    'Dokumentacija potvrđena',
    'Termin zakazan',
    'Usluge naručene',
    'Dženaza klanjana',
    'Ukop obavljen',
    'Završeno',
  ];
}

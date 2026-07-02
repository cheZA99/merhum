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

  // backend keys are English enum names, UI translates them for display
  static const List<String> phases = [
    'Registered',
    'DocumentationConfirmed',
    'AppointmentScheduled',
    'ServicesOrdered',
    'FuneralPrayerCompleted',
    'BurialCompleted',
    'Closed',
  ];

  static String labelFor(String statusName) {
    switch (statusName) {
      case 'Registered':
        return 'Registrovan';
      case 'DocumentationConfirmed':
        return 'Dokumentacija potvrđena';
      case 'AppointmentScheduled':
        return 'Termin zakazan';
      case 'ServicesOrdered':
        return 'Usluge naručene';
      case 'FuneralPrayerCompleted':
        return 'Dženaza obavljena';
      case 'BurialCompleted':
        return 'Ukop završen';
      case 'Closed':
        return 'Zatvoreno';
      default:
        return statusName;
    }
  }
}

class MosqueModel {
  final int id;
  final String naziv;
  final String adresa;
  final int gradId;
  final String gradNaziv;
  final String? telefon;
  final String? email;
  final int? kapacitet;
  final double? latitude;
  final double? longitude;
  final bool jeAktivan;

  const MosqueModel({
    required this.id,
    required this.naziv,
    required this.adresa,
    required this.gradId,
    required this.gradNaziv,
    this.telefon,
    this.email,
    this.kapacitet,
    this.latitude,
    this.longitude,
    required this.jeAktivan,
  });

  factory MosqueModel.fromJson(Map<String, dynamic> json) {
    return MosqueModel(
      id: json['id'] as int,
      naziv: json['name'] as String? ?? '',
      adresa: json['address'] as String? ?? '',
      gradId: json['cityId'] as int? ?? 0,
      gradNaziv: json['cityName'] as String? ?? '',
      telefon: json['phone'] as String?,
      email: json['email'] as String?,
      kapacitet: json['capacity'] as int?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      jeAktivan: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': naziv,
        'address': adresa,
        'cityId': gradId,
        'phone': telefon,
        'email': email,
        'capacity': kapacitet,
        'latitude': latitude,
        'longitude': longitude,
        'isActive': jeAktivan,
      };

  MosqueModel copyWith({
    int? id,
    String? naziv,
    String? adresa,
    int? gradId,
    String? gradNaziv,
    String? telefon,
    String? email,
    int? kapacitet,
    double? latitude,
    double? longitude,
    bool? jeAktivan,
  }) {
    return MosqueModel(
      id: id ?? this.id,
      naziv: naziv ?? this.naziv,
      adresa: adresa ?? this.adresa,
      gradId: gradId ?? this.gradId,
      gradNaziv: gradNaziv ?? this.gradNaziv,
      telefon: telefon ?? this.telefon,
      email: email ?? this.email,
      kapacitet: kapacitet ?? this.kapacitet,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      jeAktivan: jeAktivan ?? this.jeAktivan,
    );
  }
}

/// Form validators shared by the mobile forms, so the same rule is not written twice.
class Validators {
  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final _phone = RegExp(r'^\+?[0-9]{6,15}$');

  static String? required(String? value, String fieldLabel) {
    if (value == null || value.trim().isEmpty) return 'Unesite $fieldLabel';
    return null;
  }

  static String? name(String? value, String fieldLabel) {
    final problem = required(value, fieldLabel);
    if (problem != null) return problem;
    if (value!.trim().length < 2) return '$fieldLabel mora imati najmanje 2 znaka';
    return null;
  }

  static String? email(String? value, {bool isRequired = true}) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return isRequired ? 'Unesite email adresu' : null;
    if (!_email.hasMatch(text)) return 'Email adresa nije ispravna';
    return null;
  }

  /// Accepts an optional leading plus and 6 to 15 digits, spaces are ignored.
  static String? phone(String? value, {bool isRequired = true}) {
    final text = (value ?? '').replaceAll(' ', '').trim();
    if (text.isEmpty) return isRequired ? 'Unesite broj telefona' : null;
    if (!_phone.hasMatch(text)) return 'Broj telefona nije ispravan, npr. +38761123456';
    return null;
  }

  static String? choice<T>(T? value, String fieldLabel) {
    if (value == null) return 'Odaberite $fieldLabel';
    return null;
  }

  static String? date(DateTime? value, String fieldLabel) {
    if (value == null) return 'Odaberite $fieldLabel';
    return null;
  }

  /// Keeps a date inside a sensible window instead of accepting any year.
  static String? pastDate(DateTime? value, String fieldLabel, {int maxYearsAgo = 120}) {
    final problem = date(value, fieldLabel);
    if (problem != null) return problem;

    final now = DateTime.now();
    if (value!.isAfter(now)) return '$fieldLabel ne može biti u budućnosti';
    if (value.isBefore(DateTime(now.year - maxYearsAgo))) {
      return '$fieldLabel je predaleko u prošlosti';
    }
    return null;
  }

  static String? orderedDates(DateTime? earlier, DateTime? later, String message) {
    if (earlier == null || later == null) return null;
    if (later.isBefore(earlier)) return message;
    return null;
  }

  static String? password(String? value, {int minLength = 4}) {
    final text = value ?? '';
    if (text.isEmpty) return 'Unesite lozinku';
    if (text.length < minLength) return 'Lozinka mora imati najmanje $minLength znaka';
    return null;
  }
}

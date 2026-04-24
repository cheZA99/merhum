import 'package:intl/intl.dart';

class DateFormatter {
  static String date(DateTime? d) =>
      d == null ? '—' : DateFormat('dd.MM.yyyy.').format(d);

  static String dateTime(DateTime? d) =>
      d == null ? '—' : DateFormat("dd.MM.yyyy. 'u' HH:mm").format(d);

  static String dayDateTime(DateTime? d) {
    if (d == null) return '—';
    final day = DateFormat('EEEE', 'bs').format(d);
    final capitalized = day[0].toUpperCase() + day.substring(1);
    return '$capitalized, ${DateFormat("dd.MM.yyyy. 'u' HH:mm").format(d)}';
  }

  static String money(double amount) =>
      '${amount.toStringAsFixed(2).replaceAll('.', ',')} KM';

  static int age(DateTime birth, DateTime death) {
    int age = death.year - birth.year;
    if (death.month < birth.month ||
        (death.month == birth.month && death.day < birth.day)) {
      age--;
    }
    return age;
  }
}

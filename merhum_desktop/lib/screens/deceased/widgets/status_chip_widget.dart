import 'package:flutter/material.dart';
import '../../../utils/constants.dart';

class StatusChipWidget extends StatelessWidget {
  final String statusName;

  const StatusChipWidget({super.key, required this.statusName});

  static Color colorFor(String statusName) {
    switch (statusName) {
      case 'Registered':
        return Colors.grey;
      case 'DocumentationConfirmed':
        return Colors.blue;
      case 'AppointmentScheduled':
        return Colors.orange;
      case 'ServicesOrdered':
        return Colors.amber.shade700;
      case 'FuneralPrayerCompleted':
        return Colors.teal;
      case 'BurialCompleted':
        return Colors.green;
      case 'Closed':
        return AppColors.primary;
      default:
        return Colors.grey;
    }
  }

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

  @override
  Widget build(BuildContext context) {
    final color = colorFor(statusName);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(radius: 4, backgroundColor: color),
          const SizedBox(width: 6),
          Text(
            labelFor(statusName),
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

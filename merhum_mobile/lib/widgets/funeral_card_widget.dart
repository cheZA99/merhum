import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/date_formatter.dart';

class FuneralCardWidget extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback? onTap;

  const FuneralCardWidget({super.key, required this.data, this.onTap});

  @override
  Widget build(BuildContext context) {
    final name = data['deceasedFullName'] as String? ?? '-';
    final dtRaw = data['funeralDateTime'] as String?;
    final dt = dtRaw != null ? DateTime.tryParse(dtRaw) : null;
    final mosque = data['mosqueName'] as String? ?? '-';
    final cemetery = data['cemeteryName'] as String? ?? '-';
    final city = data['cityName'] as String?;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(name, style: AppTextStyles.heading3)),
                  if (city != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(city, style: const TextStyle(fontSize: 11, color: AppColors.primary)),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              if (dt != null) ...[
                Row(children: [
                  const Icon(Icons.access_time, size: 14, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(DateFormatter.dayDateTime(dt), style: AppTextStyles.bodyMedium),
                ]),
                const SizedBox(height: 4),
              ],
              Row(children: [
                const Icon(Icons.mosque, size: 14, color: AppColors.textLight),
                const SizedBox(width: 6),
                Expanded(child: Text(mosque, style: AppTextStyles.caption)),
              ]),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textLight),
                const SizedBox(width: 6),
                Expanded(child: Text(cemetery, style: AppTextStyles.caption)),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

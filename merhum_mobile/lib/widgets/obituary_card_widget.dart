import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../models/obituary_model.dart';
import '../utils/constants.dart';
import '../utils/date_formatter.dart';

class ObituaryCardWidget extends StatelessWidget {
  final ObituaryModel obituary;
  final VoidCallback onTap;

  const ObituaryCardWidget({super.key, required this.obituary, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _buildAvatar(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(obituary.deceasedFullName, style: AppTextStyles.heading3),
                    const SizedBox(height: 2),
                    Text(
                      DateFormatter.date(obituary.dateOfDeath),
                      style: AppTextStyles.caption,
                    ),
                    if (obituary.cityName != null) ...[
                      const SizedBox(height: 2),
                      Text(obituary.cityName!, style: AppTextStyles.caption),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.visibility_outlined, size: 14, color: AppColors.textLight),
                        const SizedBox(width: 4),
                        Text('${obituary.viewCount}', style: AppTextStyles.caption),
                        const SizedBox(width: 12),
                        const Icon(Icons.chat_bubble_outline, size: 14, color: AppColors.textLight),
                        const SizedBox(width: 4),
                        Text('${obituary.condolenceCount}', style: AppTextStyles.caption),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textLight),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    if (obituary.photoUrl != null && obituary.photoUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 25,
        backgroundImage: CachedNetworkImageProvider(obituary.photoUrl!),
        backgroundColor: AppColors.background,
      );
    }
    return CircleAvatar(
      radius: 25,
      backgroundColor: AppColors.background,
      child: const Icon(Icons.person, size: 28, color: AppColors.textLight),
    );
  }
}

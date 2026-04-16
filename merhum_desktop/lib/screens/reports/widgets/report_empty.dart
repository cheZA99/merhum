import 'package:flutter/material.dart';
import '../../../utils/constants.dart';

class ReportEmpty extends StatelessWidget {
  final String message;
  const ReportEmpty({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.bar_chart, size: 64, color: AppColors.textLight),
          const SizedBox(height: 16),
          Text(message, style: AppTextStyles.body),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../utils/constants.dart';

class ReportError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ReportError({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(message, style: const TextStyle(color: AppColors.error)),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: onRetry, child: const Text('Pokušaj ponovo')),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../models/procedure_status_model.dart';
import '../models/status_history_model.dart';
import '../utils/constants.dart';
import '../utils/date_formatter.dart';

class StatusTimelineWidget extends StatelessWidget {
  final String currentStatusName;
  final List<StatusHistoryModel> history;

  const StatusTimelineWidget({
    super.key,
    required this.currentStatusName,
    required this.history,
  });

  @override
  Widget build(BuildContext context) {
    final phases = ProcedureStatusModel.phases;
    final currentIndex = phases.indexOf(currentStatusName);

    return Column(
      children: List.generate(phases.length, (i) {
        final phase = phases[i];
        final isCompleted = i < currentIndex;
        final isCurrent = i == currentIndex;
        final isPending = i > currentIndex;

        final historyEntry = history.where((h) => h.statusName == phase).firstOrNull;

        return _TimelineItem(
          phase: phase,
          isCompleted: isCompleted,
          isCurrent: isCurrent,
          isPending: isPending,
          date: historyEntry?.changedAt,
          note: historyEntry?.note,
          isLast: i == phases.length - 1,
        );
      }),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final String phase;
  final bool isCompleted;
  final bool isCurrent;
  final bool isPending;
  final DateTime? date;
  final String? note;
  final bool isLast;

  const _TimelineItem({
    required this.phase,
    required this.isCompleted,
    required this.isCurrent,
    required this.isPending,
    this.date,
    this.note,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 40,
            child: Column(
              children: [
                _buildCircle(),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: isCompleted ? AppColors.success : AppColors.background,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 2),
                  Text(
                    ProcedureStatusModel.labelFor(phase),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                      color: isPending ? AppColors.textLight : AppColors.textDark,
                    ),
                  ),
                  if (date != null) ...[
                    const SizedBox(height: 2),
                    Text(DateFormatter.date(date), style: AppTextStyles.caption),
                  ],
                  if (note != null && note!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(note!, style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppColors.textMedium)),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircle() {
    if (isCompleted) {
      return Container(
        width: 28, height: 28,
        decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
        child: const Icon(Icons.check, size: 16, color: Colors.white),
      );
    }
    if (isCurrent) {
      return Container(
        width: 28, height: 28,
        decoration: BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 8, spreadRadius: 2)],
        ),
        child: const Icon(Icons.radio_button_checked, size: 16, color: Colors.white),
      );
    }
    return Container(
      width: 28, height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.textLight, width: 2),
        color: Colors.white,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../models/procedure_status_model.dart';
import '../../../models/status_history_model.dart';
import '../../../utils/constants.dart';
import 'status_chip_widget.dart';

class StatusTimelineWidget extends StatelessWidget {
  final List<ProcedureStatusModel> allStatuses;
  final int currentStatusOrder;
  final List<StatusHistoryModel> history;

  const StatusTimelineWidget({
    super.key,
    required this.allStatuses,
    required this.currentStatusOrder,
    required this.history,
  });

  @override
  Widget build(BuildContext context) {
    final sorted = [...allStatuses]..sort((a, b) => a.order.compareTo(b.order));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sorted.asMap().entries.map((entry) {
        final index = entry.key;
        final status = entry.value;
        final isLast = index == sorted.length - 1;

        final historyEntry = history
            .cast<StatusHistoryModel?>()
            .firstWhere((h) => h!.statusId == status.id, orElse: () => null);

        final isCompleted = status.order <= currentStatusOrder && historyEntry != null;
        final isCurrent = status.order == currentStatusOrder;
        final isPending = status.order > currentStatusOrder;

        final circleColor = (isCompleted || isCurrent)
            ? AppColors.primary
            : Colors.grey.shade400;

        final lineColor =
            isCompleted ? AppColors.primary : Colors.grey.shade300;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                CircleAvatar(
                  radius: 8,
                  backgroundColor:
                      (isCompleted || isCurrent) ? AppColors.primary : Colors.white,
                  child: CircleAvatar(
                    radius: 6,
                    backgroundColor: circleColor,
                    child: (isCompleted || isCurrent)
                        ? const Icon(Icons.check, size: 8, color: Colors.white)
                        : null,
                  ),
                ),
                if (!isLast)
                  Container(width: 2, height: 40, color: lineColor),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      StatusChipWidget.labelFor(status.name),
                      style: TextStyle(
                        fontWeight:
                            isCurrent ? FontWeight.bold : FontWeight.normal,
                        color: isPending
                            ? Colors.grey.shade500
                            : AppColors.textDark,
                        fontSize: 13,
                      ),
                    ),
                    if (historyEntry != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${_formatDateTime(historyEntry.changedAt)} - ${historyEntry.changedByUsername}',
                        style: AppTextStyles.caption,
                      ),
                      if (historyEntry.note != null &&
                          historyEntry.note!.isNotEmpty)
                        Text(
                          historyEntry.note!,
                          style: const TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: AppColors.textLight,
                          ),
                        ),
                    ] else if (isPending)
                      const Text(
                        'Na čekanju',
                        style: AppTextStyles.caption,
                      ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  String _formatDateTime(DateTime d) {
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    final hour = d.hour.toString().padLeft(2, '0');
    final minute = d.minute.toString().padLeft(2, '0');
    return '$day.$month.${d.year} $hour:$minute';
  }
}

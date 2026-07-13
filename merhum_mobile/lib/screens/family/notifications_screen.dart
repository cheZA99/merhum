import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/notification_provider.dart';
import '../../utils/constants.dart';
import '../../utils/date_formatter.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().loadNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifikacije'),
        actions: [
          Consumer<NotificationProvider>(
            builder: (_, p, __) => p.unreadCount > 0
                ? TextButton(
                    onPressed: () => p.markAllRead(),
                    child: const Text('Označi sve', style: TextStyle(color: Colors.white)),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (_, p, __) {
          if (p.loading && p.items.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          if (p.items.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Nemate notifikacija.', style: AppTextStyles.bodyMedium),
              ),
            );
          }
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => p.loadNotifications(),
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: p.items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final n = p.items[i];
                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: Icon(
                      n.isRead ? Icons.notifications_none : Icons.notifications_active,
                      color: n.isRead ? AppColors.textLight : AppColors.primary,
                    ),
                    title: Text(
                      n.title,
                      style: TextStyle(fontWeight: n.isRead ? FontWeight.w500 : FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(n.message, style: AppTextStyles.bodyMedium),
                        const SizedBox(height: 4),
                        Text(DateFormatter.dateTime(n.createdAt), style: AppTextStyles.caption),
                      ],
                    ),
                    trailing: n.isRead
                        ? null
                        : Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                          ),
                    onTap: n.isRead ? null : () => p.markRead(n.id),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

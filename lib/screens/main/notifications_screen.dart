import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_controller.dart';
import '../../data/app_data.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/section_header.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key, required this.controller, required this.onBack});

  final AppController controller;
  final VoidCallback onBack;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller.markAlertsRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final alerts = controller.alerts;
    final user = controller.user;
    final reminderHour = user?.reminderHour ?? 9;
    final reminderMinute = user?.reminderMinute ?? 0;
    final verse = verseForToday();

    return RefreshIndicator(
      onRefresh: () async {
        await controller.refreshSupportTickets();
        await controller.markAlertsRead();
        if (mounted) setState(() {});
      },
      child: ListView(
        key: const ValueKey('notifications-center'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 110),
        children: [
          const SectionHeader(
            title: 'Notifications',
            subtitle: 'Customer Care replies and your prayer reminder.',
            icon: Icons.notifications_active_outlined,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: widget.onBack,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Back'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await controller.markAlertsRead();
                    if (mounted) setState(() {});
                  },
                  icon: const Icon(Icons.done_all),
                  label: const Text('Mark read'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GlassPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Prayer Reminder',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your daily prayer reminder is set for ${_formatTime(reminderHour, reminderMinute)}.',
                  style: const TextStyle(color: AppColors.muted, height: 1.45),
                ),
                const SizedBox(height: 10),
                Text(
                  '"${verse.verse}"',
                  style: const TextStyle(fontWeight: FontWeight.w700, height: 1.45),
                ),
                const SizedBox(height: 4),
                Text(
                  verse.ref,
                  style: const TextStyle(color: AppColors.deepEmerald, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (alerts.isEmpty)
            const GlassPanel(
              child: Text(
                'No customer care replies yet.',
                style: TextStyle(color: AppColors.muted),
              ),
            )
          else ...[
            const Text(
              'Customer Care Replies',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            ...alerts.map(
              (alert) => _AlertTile(
                alert: alert,
                onTap: () async {
                  await controller.markAlertRead((alert['id'] ?? '').toString());
                  if (mounted) setState(() {});
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(int hour, int minute) {
    final localTime = TimeOfDay(hour: hour, minute: minute);
    return localTime.format(context);
  }
}

class _AlertTile extends StatelessWidget {
  const _AlertTile({required this.alert, required this.onTap});

  final Map<String, dynamic> alert;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final unread = alert['readAt'] == null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassPanel(
        child: ListTile(
          onTap: onTap,
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundColor: unread ? AppColors.leaf.withValues(alpha: .18) : AppColors.sky.withValues(alpha: .16),
            child: Icon(
              unread ? Icons.mark_email_unread_outlined : Icons.mark_email_read_outlined,
              color: AppColors.deepEmerald,
            ),
          ),
          title: Text(
            (alert['title'] ?? 'Alert').toString(),
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          subtitle: Text(
            (alert['body'] ?? '').toString(),
            style: const TextStyle(height: 1.4),
          ),
          trailing: unread ? const Icon(Icons.circle, size: 10, color: AppColors.coral) : null,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/notification_model.dart';
import '../providers/auth_provider.dart';
import '../services/notification_service.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final notifService = NotificationService();
    final uid = auth.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () => notifService.markAllRead(uid),
            child: const Text('Mark all read',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: notifService.notificationsStream(uid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final notifs = snap.data ?? [];
          if (notifs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_none,
                      size: 56, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  Text('No notifications yet.',
                      style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            );
          }
          return ListView.builder(
            itemCount: notifs.length,
            itemBuilder: (_, i) {
              final n = notifs[i];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: n.read
                      ? Colors.grey[200]
                      : const Color(0xFF1565C0).withValues(alpha: 0.12),
                  child: Icon(
                    _iconForType(n.type),
                    color: n.read ? Colors.grey : const Color(0xFF1565C0),
                    size: 20,
                  ),
                ),
                title: Text(
                  n.message,
                  style: TextStyle(
                      fontWeight:
                          n.read ? FontWeight.normal : FontWeight.w600,
                      fontSize: 14),
                ),
                subtitle: Text(
                  DateFormat('d MMM, h:mm a').format(n.createdAt),
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: n.read
                    ? null
                    : Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF1565C0),
                          shape: BoxShape.circle,
                        ),
                      ),
                onTap: () => notifService.markRead(n.id),
              );
            },
          );
        },
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'task_completed':
        return Icons.check_circle_outline;
      case 'reminder':
        return Icons.alarm;
      default:
        return Icons.assignment_outlined;
    }
  }
}

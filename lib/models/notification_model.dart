import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String toUid;
  final String message;
  final String taskId;
  final bool read;
  final DateTime createdAt;
  final String type; // 'task_assigned' | 'task_completed' | 'reminder'

  NotificationModel({
    required this.id,
    required this.toUid,
    required this.message,
    required this.taskId,
    required this.read,
    required this.createdAt,
    required this.type,
  });

  factory NotificationModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      toUid: d['toUid'] ?? '',
      message: d['message'] ?? '',
      taskId: d['taskId'] ?? '',
      read: d['read'] ?? false,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      type: d['type'] ?? 'task_assigned',
    );
  }

  Map<String, dynamic> toMap() => {
        'toUid': toUid,
        'message': message,
        'taskId': taskId,
        'read': read,
        'createdAt': FieldValue.serverTimestamp(),
        'type': type,
      };
}

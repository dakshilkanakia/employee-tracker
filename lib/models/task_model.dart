import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum TaskStatus { pending, inProgress, completed }

enum TaskPriority { high, medium, low }

extension TaskStatusExt on TaskStatus {
  String get value {
    switch (this) {
      case TaskStatus.pending:
        return 'pending';
      case TaskStatus.inProgress:
        return 'in_progress';
      case TaskStatus.completed:
        return 'completed';
    }
  }

  String get label {
    switch (this) {
      case TaskStatus.pending:
        return 'Pending';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.completed:
        return 'Completed';
    }
  }

  static TaskStatus fromString(String s) {
    switch (s) {
      case 'in_progress':
        return TaskStatus.inProgress;
      case 'completed':
        return TaskStatus.completed;
      default:
        return TaskStatus.pending;
    }
  }
}

extension TaskPriorityExt on TaskPriority {
  String get value {
    switch (this) {
      case TaskPriority.high:
        return 'high';
      case TaskPriority.medium:
        return 'medium';
      case TaskPriority.low:
        return 'low';
    }
  }

  String get label {
    switch (this) {
      case TaskPriority.high:
        return 'High';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.low:
        return 'Low';
    }
  }

  Color get color {
    switch (this) {
      case TaskPriority.high:
        return const Color(0xFFE53935);
      case TaskPriority.medium:
        return const Color(0xFFFB8C00);
      case TaskPriority.low:
        return const Color(0xFF43A047);
    }
  }

  static TaskPriority fromString(String s) {
    switch (s) {
      case 'high':
        return TaskPriority.high;
      case 'medium':
        return TaskPriority.medium;
      default:
        return TaskPriority.low;
    }
  }
}

class TaskModel {
  final String id;
  final String title;
  final String description;
  final String orgId;
  final List<String> assignedTo;
  final String assignedBy;
  final TaskStatus status;
  final TaskPriority priority;
  final String color; // hex e.g. '#4CAF50'
  final DateTime dateAssigned;
  final DateTime dueDate;
  final bool isGroupTask;
  final List<String> completedBy;
  final DateTime? completedAt;
  final String notes;
  final List<String> proofImageUrls;

  TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.orgId,
    required this.assignedTo,
    required this.assignedBy,
    required this.status,
    required this.priority,
    required this.color,
    required this.dateAssigned,
    required this.dueDate,
    required this.isGroupTask,
    required this.completedBy,
    this.completedAt,
    this.notes = '',
    this.proofImageUrls = const [],
  });

  bool get isOverdue =>
      status != TaskStatus.completed && dueDate.isBefore(DateTime.now());

  bool hasUserCompleted(String uid) => completedBy.contains(uid);

  factory TaskModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return TaskModel(
      id: doc.id,
      title: d['title'] ?? '',
      description: d['description'] ?? '',
      orgId: d['orgId'] ?? '',
      assignedTo: List<String>.from(d['assignedTo'] ?? []),
      assignedBy: d['assignedBy'] ?? '',
      status: TaskStatusExt.fromString(d['status'] ?? 'pending'),
      priority: TaskPriorityExt.fromString(d['priority'] ?? 'low'),
      color: d['color'] ?? '#2196F3',
      dateAssigned:
          (d['dateAssigned'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dueDate: (d['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isGroupTask: d['isGroupTask'] ?? false,
      completedBy: List<String>.from(d['completedBy'] ?? []),
      completedAt: (d['completedAt'] as Timestamp?)?.toDate(),
      notes: d['notes'] ?? '',
      proofImageUrls: List<String>.from(d['proofImageUrls'] ?? []),
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'description': description,
        'orgId': orgId,
        'assignedTo': assignedTo,
        'assignedBy': assignedBy,
        'status': status.value,
        'priority': priority.value,
        'color': color,
        'dateAssigned': FieldValue.serverTimestamp(),
        'dueDate': Timestamp.fromDate(dueDate),
        'isGroupTask': isGroupTask,
        'completedBy': completedBy,
        'completedAt': completedAt != null
            ? Timestamp.fromDate(completedAt!)
            : null,
        'notes': notes,
        'proofImageUrls': proofImageUrls,
      };
}

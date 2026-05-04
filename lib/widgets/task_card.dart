import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task_model.dart';
import 'priority_badge.dart';

class TaskCard extends StatelessWidget {
  final TaskModel task;
  final Map<String, String> assigneeNames; // uid -> name
  final VoidCallback? onTap;
  final bool showAssignees;

  const TaskCard({
    super.key,
    required this.task,
    this.assigneeNames = const {},
    this.onTap,
    this.showAssignees = true,
  });

  Color get _cardColor {
    try {
      final hex = task.color.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return const Color(0xFF2196F3);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOverdue = task.isOverdue;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isOverdue
            ? const BorderSide(color: Color(0xFFE53935), width: 1.5)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // colored top strip
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: _cardColor,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          task.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      PriorityBadge(priority: task.priority, small: true),
                    ],
                  ),
                  if (task.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      task.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _StatusChip(status: task.status),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.calendar_today,
                        size: 12,
                        color: isOverdue ? Colors.red : Colors.grey[500],
                      ),
                      const SizedBox(width: 3),
                      Text(
                        DateFormat('d MMM').format(task.dueDate),
                        style: TextStyle(
                          fontSize: 12,
                          color: isOverdue ? Colors.red : Colors.grey[600],
                          fontWeight: isOverdue ? FontWeight.w600 : null,
                        ),
                      ),
                      if (isOverdue) ...[
                        const SizedBox(width: 4),
                        const Text(
                          'OVERDUE',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                      const Spacer(),
                      if (task.isGroupTask)
                        const Tooltip(
                          message: 'Group task',
                          child: Icon(Icons.group, size: 16, color: Colors.grey),
                        ),
                      if (task.proofImageUrls.isNotEmpty) ...[
                        const SizedBox(width: 4),
                        Icon(Icons.photo_camera,
                            size: 16, color: Colors.grey[500]),
                      ],
                    ],
                  ),
                  if (showAssignees && assigneeNames.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 4,
                      children: task.assignedTo.map((uid) {
                        final name = assigneeNames[uid] ?? uid;
                        return Chip(
                          label: Text(
                            name,
                            style: const TextStyle(fontSize: 11),
                          ),
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final TaskStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case TaskStatus.pending:
        color = Colors.grey;
        break;
      case TaskStatus.inProgress:
        color = Colors.orange;
        break;
      case TaskStatus.completed:
        color = Colors.green;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

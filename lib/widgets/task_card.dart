import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_colors.dart';
import '../models/task_model.dart';
import 'priority_badge.dart';

class TaskCard extends StatelessWidget {
  final TaskModel task;
  final Map<String, String> assigneeNames;
  final VoidCallback? onTap;
  final bool showAssignees;

  const TaskCard({
    super.key,
    required this.task,
    this.assigneeNames = const {},
    this.onTap,
    this.showAssignees = true,
  });

  Color get _accentColor {
    try {
      final hex = task.color.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOverdue = task.isOverdue;
    final hasTime = task.dueDate.hour != 0 || task.dueDate.minute != 0;
    final fmt = DateFormat(hasTime ? 'd MMM, h:mm a' : 'd MMM');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOverdue
              ? AppColors.error.withValues(alpha: 0.4)
              : AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 4, color: _accentColor),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                task.title,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
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
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _StatusPill(status: task.status),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 11,
                              color: isOverdue
                                  ? AppColors.error
                                  : AppColors.textMuted,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              fmt.format(task.dueDate),
                              style: TextStyle(
                                fontSize: 11,
                                color: isOverdue
                                    ? AppColors.error
                                    : AppColors.textSecondary,
                                fontWeight: isOverdue
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                              ),
                            ),
                            if (isOverdue) ...[
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.error.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'OVERDUE',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: AppColors.error,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                            const Spacer(),
                            if (task.isGroupTask)
                              const Icon(Icons.group_outlined,
                                  size: 14, color: AppColors.textMuted),
                            if (task.proofImageUrls.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              const Icon(Icons.photo_camera_outlined,
                                  size: 14, color: AppColors.textMuted),
                            ],
                          ],
                        ),
                        if (showAssignees && assigneeNames.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          _AssigneeRow(
                            assignedTo: task.assignedTo,
                            nameMap: assigneeNames,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final TaskStatus status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    Color bg;
    switch (status) {
      case TaskStatus.pending:
        color = AppColors.statusPending;
        bg = AppColors.statusPendingSurface;
        break;
      case TaskStatus.inProgress:
        color = AppColors.statusInProgress;
        bg = AppColors.statusInProgressSurface;
        break;
      case TaskStatus.completed:
        color = AppColors.statusDone;
        bg = AppColors.statusDoneSurface;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _AssigneeRow extends StatelessWidget {
  final List<String> assignedTo;
  final Map<String, String> nameMap;

  const _AssigneeRow({required this.assignedTo, required this.nameMap});

  @override
  Widget build(BuildContext context) {
    final names = assignedTo.map((uid) => nameMap[uid] ?? uid).toList();
    if (names.isEmpty) return const SizedBox.shrink();
    final shown = names.length.clamp(1, 3);

    return Row(
      children: [
        SizedBox(
          height: 20,
          width: (shown * 14 + 6).toDouble(),
          child: Stack(
            children: [
              for (int i = 0; i < shown; i++)
                Positioned(
                  left: (i * 14).toDouble(),
                  child: CircleAvatar(
                    radius: 10,
                    backgroundColor: AppColors.primarySurface,
                    child: Text(
                      names[i].isNotEmpty ? names[i][0].toUpperCase() : '?',
                      style: const TextStyle(
                        fontSize: 9,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            names.length == 1
                ? names[0]
                : names.length == 2
                    ? '${names[0]}, ${names[1]}'
                    : '${names[0]} +${names.length - 1}',
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

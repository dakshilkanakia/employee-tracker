import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/task_model.dart';
import '../../models/user_model.dart';
import '../../providers/task_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/priority_badge.dart';
import '../../widgets/proof_image_viewer.dart';

class ManagerTaskDetailScreen extends StatelessWidget {
  final String taskId;
  const ManagerTaskDetailScreen({super.key, required this.taskId});

  @override
  Widget build(BuildContext context) {
    final taskProv = context.read<TaskProvider>();
    return StreamBuilder<TaskModel?>(
      stream: taskProv.taskStream(taskId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        final task = snap.data;
        if (task == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Task')),
            body: const Center(child: Text('Task not found.')),
          );
        }
        return _TaskDetailBody(task: task);
      },
    );
  }
}

class _TaskDetailBody extends StatefulWidget {
  final TaskModel task;
  const _TaskDetailBody({required this.task});

  @override
  State<_TaskDetailBody> createState() => _TaskDetailBodyState();
}

class _TaskDetailBodyState extends State<_TaskDetailBody> {
  Map<String, UserModel> _userMap = {};

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final uids = {
      ...widget.task.assignedTo,
      widget.task.assignedBy,
    }.toList();
    final map = await context.read<UserProvider>().getUserMap(uids);
    if (mounted) setState(() => _userMap = map);
  }

  Color get _taskColor {
    try {
      final hex = widget.task.color.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return AppColors.primary;
    }
  }

  Future<void> _deleteTask() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Task?'),
        content: const Text(
            'This action cannot be undone. All proof images will be lost.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    final ok = await context.read<TaskProvider>().deleteTask(widget.task.id);
    if (ok && mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final fmt = DateFormat('d MMM yyyy');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Task Detail'),
        backgroundColor: AppColors.background,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            onPressed: _deleteTask,
            tooltip: 'Delete task',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title card with accent
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
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
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(width: 4, color: _taskColor),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
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
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  PriorityBadge(priority: task.priority),
                                ],
                              ),
                              if (task.description.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  task.description,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                    height: 1.5,
                                  ),
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
            const SizedBox(height: 12),
            // Meta info
            _InfoCard(
              children: [
                _MetaRow('Status', task.status.label, Icons.info_outline),
                _MetaRow(
                  'Assigned by',
                  _userMap[task.assignedBy]?.name ?? '…',
                  Icons.person_outline,
                ),
                _MetaRow(
                  'Assigned on',
                  fmt.format(task.dateAssigned),
                  Icons.calendar_today_outlined,
                ),
                _MetaRow(
                  'Due date',
                  fmt.format(task.dueDate),
                  Icons.event_outlined,
                  valueColor: task.isOverdue ? AppColors.error : null,
                ),
                if (task.completedAt != null)
                  _MetaRow(
                    'Completed',
                    fmt.format(task.completedAt!),
                    Icons.check_circle_outline,
                    valueColor: AppColors.statusDone,
                  ),
                if (task.notes.isNotEmpty)
                  _MetaRow('Notes', task.notes, Icons.notes_outlined),
              ],
            ),
            const SizedBox(height: 16),
            // Assignees
            const Text(
              'Assignees',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            _InfoCard(
              children: task.assignedTo.map((uid) {
                final name = _userMap[uid]?.name ?? uid;
                final done = task.hasUserCompleted(uid);
                final initial =
                    name.isNotEmpty ? name[0].toUpperCase() : '?';
                return ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  leading: CircleAvatar(
                    radius: 18,
                    backgroundColor:
                        done ? AppColors.statusDoneSurface : AppColors.border,
                    child: Text(
                      initial,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: done
                            ? AppColors.statusDone
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                  title: Text(name,
                      style: const TextStyle(fontSize: 14)),
                  trailing: done
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.statusDoneSurface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: AppColors.statusDone
                                    .withValues(alpha: 0.3)),
                          ),
                          child: const Text(
                            'Completed',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.statusDone,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      : Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.statusPendingSurface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: AppColors.statusPending
                                    .withValues(alpha: 0.3)),
                          ),
                          child: const Text(
                            'Pending',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.statusPending,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                );
              }).toList(),
            ),
            if (task.proofImageUrls.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Proof Images',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              ProofImageViewer(imageUrls: task.proofImageUrls),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  const _MetaRow(this.label, this.value, this.icon, {this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.textMuted),
          const SizedBox(width: 10),
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: valueColor ?? AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

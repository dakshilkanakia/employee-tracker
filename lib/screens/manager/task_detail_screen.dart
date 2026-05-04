import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
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
      return const Color(0xFF2196F3);
    }
  }

  Future<void> _deleteTask() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Task?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child:
                  const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    final ok =
        await context.read<TaskProvider>().deleteTask(widget.task.id);
    if (ok && mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final fmt = DateFormat('d MMM yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Detail'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
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
            // header
            Container(
              decoration: BoxDecoration(
                border: Border(
                    left: BorderSide(color: _taskColor, width: 4)),
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          task.title,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                      PriorityBadge(priority: task.priority),
                    ],
                  ),
                  if (task.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(task.description,
                        style: TextStyle(
                            fontSize: 14, color: Colors.grey[700])),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            // meta info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _MetaRow(
                        label: 'Status',
                        value: task.status.label,
                        icon: Icons.info_outline),
                    _MetaRow(
                        label: 'Assigned by',
                        value: _userMap[task.assignedBy]?.name ?? '…',
                        icon: Icons.person_outline),
                    _MetaRow(
                        label: 'Assigned on',
                        value: fmt.format(task.dateAssigned),
                        icon: Icons.calendar_today_outlined),
                    _MetaRow(
                        label: 'Due date',
                        value: fmt.format(task.dueDate),
                        icon: Icons.event_outlined,
                        valueColor: task.isOverdue ? Colors.red : null),
                    if (task.completedAt != null)
                      _MetaRow(
                          label: 'Completed',
                          value: fmt.format(task.completedAt!),
                          icon: Icons.check_circle_outline,
                          valueColor: Colors.green),
                    if (task.notes.isNotEmpty)
                      _MetaRow(
                          label: 'Notes',
                          value: task.notes,
                          icon: Icons.notes_outlined),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // assignees + completion
            const Text('Assignees',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ...task.assignedTo.map((uid) {
              final name = _userMap[uid]?.name ?? uid;
              final done = task.hasUserCompleted(uid);
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor:
                      done ? Colors.green : Colors.grey[300],
                  child: Icon(
                      done ? Icons.check : Icons.person_outline,
                      color: Colors.white,
                      size: 18),
                ),
                title: Text(name),
                trailing: done
                    ? const Chip(
                        label: Text('Done',
                            style: TextStyle(
                                color: Colors.green, fontSize: 12)),
                        backgroundColor: Color(0xFFE8F5E9),
                      )
                    : const Chip(
                        label: Text('Pending',
                            style: TextStyle(
                                color: Colors.orange, fontSize: 12)),
                        backgroundColor: Color(0xFFFFF3E0),
                      ),
              );
            }),
            if (task.proofImageUrls.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Proof Images',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
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

class _MetaRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  const _MetaRow({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey[500]),
          const SizedBox(width: 10),
          SizedBox(
            width: 90,
            child: Text(label,
                style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: valueColor),
            ),
          ),
        ],
      ),
    );
  }
}

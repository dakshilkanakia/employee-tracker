import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/task_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/task_card.dart';

class ManagerDashboardScreen extends StatefulWidget {
  const ManagerDashboardScreen({super.key});

  @override
  State<ManagerDashboardScreen> createState() => _ManagerDashboardScreenState();
}

class _ManagerDashboardScreenState extends State<ManagerDashboardScreen> {
  String _filter = 'pending';
  String? _filterEmployeeUid;
  List<UserModel> _employees = [];

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    final auth = context.read<AuthProvider>();
    final userProv = context.read<UserProvider>();
    final emps = await userProv.orgEmployeesStream(auth.currentUser!.orgId).first;
    if (mounted) setState(() => _employees = emps);
  }

  List<TaskModel> _applyFilters(List<TaskModel> tasks) {
    return tasks.where((t) {
      final statusMatch = switch (_filter) {
        'pending' => t.status == TaskStatus.pending,
        'in_progress' => t.status == TaskStatus.inProgress,
        'completed' => t.status == TaskStatus.completed,
        'overdue' => t.isOverdue,
        _ => true,
      };
      final empMatch = _filterEmployeeUid == null ||
          t.assignedTo.contains(_filterEmployeeUid);
      return statusMatch && empMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser!;
    final taskProv = context.read<TaskProvider>();

    return AppShell(
      navIndex: 0,
      isManager: true,
      title: 'Tasks',
      actions: [
        IconButton(
          icon: const Icon(Icons.add),
          tooltip: 'New Task',
          onPressed: () => context.push('/manager/create-task'),
        ),
      ],
      child: Stack(
        children: [
          Column(
            children: [
              _StatsBar(orgId: user.orgId),
              _FilterBar(
                selected: _filter,
                onChanged: (f) => setState(() => _filter = f),
                employees: _employees,
                selectedEmployee: _filterEmployeeUid,
                onEmployeeChanged: (uid) =>
                    setState(() => _filterEmployeeUid = uid),
              ),
              Expanded(
                child: StreamBuilder<List<TaskModel>>(
                  stream: taskProv.orgTasksStream(user.orgId),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final tasks = _applyFilters(snap.data ?? []);
                    if (tasks.isEmpty) {
                      return _EmptyState(filter: _filter);
                    }
                    return FutureBuilder<Map<String, UserModel>>(
                      future: _buildUserMap(tasks),
                      builder: (context, userSnap) {
                        final nameMap = (userSnap.data ?? {})
                            .map((uid, u) => MapEntry(uid, u.name));
                        return ListView.builder(
                          padding: const EdgeInsets.only(top: 8, bottom: 100),
                          itemCount: tasks.length,
                          itemBuilder: (_, i) => TaskCard(
                            task: tasks[i],
                            assigneeNames: nameMap,
                            onTap: () =>
                                context.push('/manager/task/${tasks[i].id}'),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          // FAB
          Positioned(
            right: 20,
            bottom: 20,
            child: FloatingActionButton.extended(
              onPressed: () => context.push('/manager/create-task'),
              icon: const Icon(Icons.add),
              label: const Text('New Task'),
            ),
          ),
        ],
      ),
    );
  }

  Future<Map<String, UserModel>> _buildUserMap(List<TaskModel> tasks) {
    final uids = tasks.expand((t) => t.assignedTo).toSet().toList();
    return context.read<UserProvider>().getUserMap(uids);
  }
}

class _FilterBar extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  final List<UserModel> employees;
  final String? selectedEmployee;
  final ValueChanged<String?> onEmployeeChanged;

  const _FilterBar({
    required this.selected,
    required this.onChanged,
    required this.employees,
    required this.selectedEmployee,
    required this.onEmployeeChanged,
  });

  @override
  Widget build(BuildContext context) {
    const filters = [
      ('all', 'All'),
      ('pending', 'Pending'),
      ('in_progress', 'In Progress'),
      ('completed', 'Done'),
      ('overdue', 'Overdue'),
    ];

    return Container(
      color: AppColors.surface,
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Row(
              children: filters.map((f) {
                final active = selected == f.$1;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _FilterChip(
                    label: f.$2,
                    active: active,
                    onTap: () => onChanged(f.$1),
                  ),
                );
              }).toList(),
            ),
          ),
          if (employees.isNotEmpty) ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
              child: Row(
                children: [
                  _FilterChip(
                    label: 'All Employees',
                    active: selectedEmployee == null,
                    onTap: () => onEmployeeChanged(null),
                    small: true,
                  ),
                  const SizedBox(width: 8),
                  ...employees.map((e) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _FilterChip(
                          label: e.name,
                          active: selectedEmployee == e.uid,
                          onTap: () => onEmployeeChanged(e.uid),
                          small: true,
                        ),
                      )),
                ],
              ),
            ),
          ] else
            const SizedBox(height: 10),
          const Divider(height: 1),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  final bool small;

  const _FilterChip({
    required this.label,
    required this.active,
    required this.onTap,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(
          horizontal: small ? 10 : 12,
          vertical: small ? 5 : 6,
        ),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: small ? 11 : 12,
            fontWeight: FontWeight.w500,
            color: active ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _StatsBar extends StatelessWidget {
  final String orgId;
  const _StatsBar({required this.orgId});

  @override
  Widget build(BuildContext context) {
    final taskProv = context.read<TaskProvider>();
    return StreamBuilder<List<TaskModel>>(
      stream: taskProv.orgTasksStream(orgId),
      builder: (context, snap) {
        final tasks = snap.data ?? [];
        final pending =
            tasks.where((t) => t.status == TaskStatus.pending).length;
        final inProg =
            tasks.where((t) => t.status == TaskStatus.inProgress).length;
        final done =
            tasks.where((t) => t.status == TaskStatus.completed).length;
        final overdue = tasks.where((t) => t.isOverdue).length;

        return Container(
          color: AppColors.surface,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              _StatPill('${tasks.length}', 'Total',
                  AppColors.primary, AppColors.primarySurface),
              const SizedBox(width: 8),
              _StatPill('$pending', 'Pending',
                  AppColors.statusPending, AppColors.statusPendingSurface),
              const SizedBox(width: 8),
              _StatPill('$inProg', 'Active',
                  AppColors.statusInProgress, AppColors.statusInProgressSurface),
              const SizedBox(width: 8),
              _StatPill('$done', 'Done',
                  AppColors.statusDone, AppColors.statusDoneSurface),
              if (overdue > 0) ...[
                const SizedBox(width: 8),
                _StatPill('$overdue', 'Overdue',
                    AppColors.error, AppColors.priorityHighSurface),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _StatPill extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final Color surface;

  const _StatPill(this.value, this.label, this.color, this.surface);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String filter;
  const _EmptyState({required this.filter});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.task_outlined,
                size: 36, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          Text(
            filter == 'all' ? 'No tasks yet' : 'No ${filter.replaceAll('_', ' ')} tasks',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            filter == 'all'
                ? 'Tap "New Task" to create your first task.'
                : 'Try a different filter.',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

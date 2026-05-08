import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/task_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/task_provider.dart';
import '../../services/location_service.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/task_card.dart';

class MyTasksScreen extends StatefulWidget {
  const MyTasksScreen({super.key});

  @override
  State<MyTasksScreen> createState() => _MyTasksScreenState();
}

class _MyTasksScreenState extends State<MyTasksScreen> {
  String _filter = 'pending';
  Timer? _locationTimer;

  @override
  void initState() {
    super.initState();
    _startLocationUpdates();
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
  }

  void _startLocationUpdates() {
    final uid = context.read<AuthProvider>().currentUser?.uid;
    if (uid == null) return;
    LocationService.updateLocation(uid);
    _locationTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => LocationService.updateLocation(uid),
    );
  }

  List<TaskModel> _applyFilter(List<TaskModel> tasks) {
    return tasks.where((t) {
      return switch (_filter) {
        'pending' => t.status == TaskStatus.pending,
        'in_progress' => t.status == TaskStatus.inProgress,
        'completed' => t.status == TaskStatus.completed,
        'overdue' => t.isOverdue,
        _ => true,
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final taskProv = context.read<TaskProvider>();
    final user = auth.currentUser!;

    return AppShell(
      navIndex: 0,
      isManager: false,
      title: 'Hi, ${user.name.split(' ').first}',
      child: Column(
        children: [
          _FilterBar(
            selected: _filter,
            onChanged: (f) => setState(() => _filter = f),
          ),
          Expanded(
            child: StreamBuilder<List<TaskModel>>(
              stream: taskProv.employeeTasksStream(user.orgId, user.uid),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final tasks = _applyFilter(snap.data ?? []);
                if (tasks.isEmpty) {
                  return _EmptyState(filter: _filter);
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 20),
                  itemCount: tasks.length,
                  itemBuilder: (_, i) => TaskCard(
                    task: tasks[i],
                    showAssignees: false,
                    onTap: () =>
                        context.push('/employee/task/${tasks[i].id}'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _FilterBar({required this.selected, required this.onChanged});

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
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Row(
              children: filters.map((f) {
                final active = selected == f.$1;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => onChanged(f.$1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: active ? AppColors.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: active ? AppColors.primary : AppColors.border,
                        ),
                      ),
                      child: Text(
                        f.$2,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: active
                              ? Colors.white
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const Divider(height: 1),
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
            decoration: const BoxDecoration(
              color: AppColors.primarySurface,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.assignment_outlined,
                size: 36, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          Text(
            filter == 'all'
                ? 'No tasks assigned yet'
                : 'No ${filter.replaceAll('_', ' ')} tasks',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'You\'re all caught up!',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

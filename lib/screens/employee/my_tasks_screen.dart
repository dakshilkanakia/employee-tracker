import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/task_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/task_provider.dart';
import '../../widgets/task_card.dart';

class MyTasksScreen extends StatefulWidget {
  const MyTasksScreen({super.key});

  @override
  State<MyTasksScreen> createState() => _MyTasksScreenState();
}

class _MyTasksScreenState extends State<MyTasksScreen> {
  String _filter = 'pending';

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

    return Scaffold(
      appBar: AppBar(
        title: Text('Hi, ${user.name.split(' ').first}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push('/employee/notifications'),
          ),
        ],
      ),
      body: Column(
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
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.task_outlined,
                            size: 56, color: Colors.grey[400]),
                        const SizedBox(height: 12),
                        Text(
                          _filter == 'all'
                              ? 'No tasks assigned to you yet.'
                              : 'No tasks match this filter.',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 20),
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (i) {
          if (i == 1) context.go('/employee/all-tasks');
          if (i == 2) context.go('/employee/settings');
        },
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.assignment_outlined), label: 'My Tasks'),
          BottomNavigationBarItem(
              icon: Icon(Icons.group_outlined), label: 'Team Tasks'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outlined), label: 'Profile'),
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
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: filters.map((f) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(f.$2),
                selected: selected == f.$1,
                onSelected: (_) => onChanged(f.$1),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/task_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/task_card.dart';

class ManagerDashboardScreen extends StatefulWidget {
  const ManagerDashboardScreen({super.key});

  @override
  State<ManagerDashboardScreen> createState() => _ManagerDashboardScreenState();
}

class _ManagerDashboardScreenState extends State<ManagerDashboardScreen> {
  String _filter = 'pending'; // all | pending | in_progress | completed | overdue
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
    final user = auth.currentUser!;
    final emps = await userProv.orgEmployeesStream(user.orgId).first;
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push('/manager/notifications'),
            tooltip: 'Notifications',
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/manager/settings'),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: Column(
        children: [
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
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.task_outlined,
                            size: 56, color: Colors.grey[400]),
                        const SizedBox(height: 12),
                        Text(
                          _filter == 'all'
                              ? 'No tasks yet. Create one!'
                              : 'No tasks match this filter.',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }
                return FutureBuilder<Map<String, UserModel>>(
                  future: _buildUserMap(tasks),
                  builder: (context, userSnap) {
                    final userMap = userSnap.data ?? {};
                    final nameMap = userMap
                        .map((uid, u) => MapEntry(uid, u.name));
                    return ListView.builder(
                      padding: const EdgeInsets.only(bottom: 80),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/manager/create-task'),
        icon: const Icon(Icons.add),
        label: const Text('New Task'),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (i) {
          if (i == 1) context.go('/manager/employees');
          if (i == 2) context.go('/manager/performance');
        },
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined), label: 'Tasks'),
          BottomNavigationBarItem(
              icon: Icon(Icons.people_outlined), label: 'Employees'),
          BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined), label: 'Performance'),
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
      color: Colors.white,
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: filters.map((f) {
                final active = selected == f.$1;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(f.$2),
                    selected: active,
                    onSelected: (_) => onChanged(f.$1),
                  ),
                );
              }).toList(),
            ),
          ),
          if (employees.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('All Employees'),
                    selected: selectedEmployee == null,
                    onSelected: (_) => onEmployeeChanged(null),
                  ),
                  const SizedBox(width: 8),
                  ...employees.map((e) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(e.name),
                          selected: selectedEmployee == e.uid,
                          onSelected: (_) => onEmployeeChanged(e.uid),
                        ),
                      )),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

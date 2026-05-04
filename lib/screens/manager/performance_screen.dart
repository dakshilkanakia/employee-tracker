import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/task_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/user_provider.dart';

class PerformanceScreen extends StatefulWidget {
  const PerformanceScreen({super.key});

  @override
  State<PerformanceScreen> createState() => _PerformanceScreenState();
}

class _PerformanceScreenState extends State<PerformanceScreen> {
  List<UserModel> _employees = [];

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    final auth = context.read<AuthProvider>();
    final userProv = context.read<UserProvider>();
    final emps =
        await userProv.orgEmployeesStream(auth.currentUser!.orgId).first;
    if (mounted) setState(() => _employees = emps);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final taskProv = context.read<TaskProvider>();
    final orgId = auth.currentUser!.orgId;

    return Scaffold(
      appBar: AppBar(title: const Text('Performance')),
      body: StreamBuilder<List<TaskModel>>(
        stream: taskProv.orgTasksStream(orgId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final tasks = snap.data ?? [];
          final stats = _buildStats(tasks);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SummaryCards(tasks: tasks),
                const SizedBox(height: 24),
                const Text(
                  'Completion Rate by Employee',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                _employees.isEmpty
                    ? const Text('No employees yet.')
                    : _CompletionChart(
                        employees: _employees, stats: stats),
                const SizedBox(height: 24),
                const Text(
                  'Employee Breakdown',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                ..._employees.map((e) => _EmployeeStatCard(
                      employee: e,
                      stat: stats[e.uid] ??
                          _EmployeeStat(uid: e.uid),
                    )),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        onTap: (i) {
          if (i == 0) context.go('/manager');
          if (i == 1) context.go('/manager/employees');
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

  Map<String, _EmployeeStat> _buildStats(List<TaskModel> tasks) {
    final stats = <String, _EmployeeStat>{};
    for (final task in tasks) {
      for (final uid in task.assignedTo) {
        stats[uid] ??= _EmployeeStat(uid: uid);
        stats[uid]!.totalAssigned++;
        if (task.completedBy.contains(uid)) {
          stats[uid]!.completed++;
          final onTime = task.completedAt != null &&
              !task.completedAt!.isAfter(task.dueDate);
          if (onTime) stats[uid]!.onTime++;
        }
        if (task.isOverdue && !task.completedBy.contains(uid)) {
          stats[uid]!.overdue++;
        }
      }
    }
    return stats;
  }
}

class _EmployeeStat {
  final String uid;
  int totalAssigned = 0;
  int completed = 0;
  int onTime = 0;
  int overdue = 0;

  _EmployeeStat({required this.uid});

  double get completionRate =>
      totalAssigned == 0 ? 0 : completed / totalAssigned;
}

class _SummaryCards extends StatelessWidget {
  final List<TaskModel> tasks;
  const _SummaryCards({required this.tasks});

  @override
  Widget build(BuildContext context) {
    final total = tasks.length;
    final done = tasks.where((t) => t.status == TaskStatus.completed).length;
    final overdue = tasks.where((t) => t.isOverdue).length;
    final inProg =
        tasks.where((t) => t.status == TaskStatus.inProgress).length;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _StatCard(label: 'Total Tasks', value: '$total', color: Colors.blue),
        _StatCard(
            label: 'Completed', value: '$done', color: Colors.green),
        _StatCard(
            label: 'In Progress', value: '$inProg', color: Colors.orange),
        _StatCard(label: 'Overdue', value: '$overdue', color: Colors.red),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCard(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: color)),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}

class _CompletionChart extends StatelessWidget {
  final List<UserModel> employees;
  final Map<String, _EmployeeStat> stats;

  const _CompletionChart(
      {required this.employees, required this.stats});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 100,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, _, rod, __) {
                final emp = employees[group.x];
                return BarTooltipItem(
                  '${emp.name}\n${rod.toY.toStringAsFixed(0)}%',
                  const TextStyle(color: Colors.white, fontSize: 12),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (v, _) => Text(
                  '${v.toInt()}%',
                  style: const TextStyle(fontSize: 10),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  if (i < 0 || i >= employees.length) return const SizedBox();
                  final name = employees[i].name.split(' ').first;
                  return Text(name,
                      style: const TextStyle(fontSize: 10));
                },
              ),
            ),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: employees.asMap().entries.map((entry) {
            final rate =
                (stats[entry.value.uid]?.completionRate ?? 0) * 100;
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: rate,
                  color: const Color(0xFF1565C0),
                  width: 20,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4)),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _EmployeeStatCard extends StatelessWidget {
  final UserModel employee;
  final _EmployeeStat stat;

  const _EmployeeStatCard(
      {required this.employee, required this.stat});

  @override
  Widget build(BuildContext context) {
    final rate = (stat.completionRate * 100).toStringAsFixed(0);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(employee.name,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: [
                _MiniStat(label: 'Assigned', value: '${stat.totalAssigned}'),
                _MiniStat(
                    label: 'Completed',
                    value: '${stat.completed}',
                    color: Colors.green),
                _MiniStat(
                    label: 'On Time',
                    value: '${stat.onTime}',
                    color: Colors.blue),
                _MiniStat(
                    label: 'Overdue',
                    value: '${stat.overdue}',
                    color: Colors.red),
                _MiniStat(
                    label: 'Rate',
                    value: '$rate%',
                    color: const Color(0xFF1565C0)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _MiniStat({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color ?? Colors.black87)),
          Text(label,
              style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }
}

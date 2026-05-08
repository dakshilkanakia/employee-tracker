import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/task_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/app_shell.dart';

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

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final taskProv = context.read<TaskProvider>();
    final orgId = auth.currentUser!.orgId;

    return AppShell(
      navIndex: 2,
      isManager: true,
      title: 'Performance',
      child: StreamBuilder<List<TaskModel>>(
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
                _SummaryGrid(tasks: tasks),
                const SizedBox(height: 24),
                _SectionHeader('Completion Rate by Employee'),
                const SizedBox(height: 12),
                _employees.isEmpty
                    ? const _EmptyEmployees()
                    : _CompletionChart(
                        employees: _employees, stats: stats),
                const SizedBox(height: 24),
                _SectionHeader('Employee Breakdown'),
                const SizedBox(height: 8),
                ..._employees.map((e) => _EmployeeStatCard(
                      employee: e,
                      stat: stats[e.uid] ?? _EmployeeStat(uid: e.uid),
                    )),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
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

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  final List<TaskModel> tasks;
  const _SummaryGrid({required this.tasks});

  @override
  Widget build(BuildContext context) {
    final total = tasks.length;
    final done = tasks.where((t) => t.status == TaskStatus.completed).length;
    final inProg = tasks.where((t) => t.status == TaskStatus.inProgress).length;
    final overdue = tasks.where((t) => t.isOverdue).length;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.7,
      children: [
        _StatTile(
          label: 'Total Tasks',
          value: '$total',
          icon: Icons.task_outlined,
          color: AppColors.primary,
          surface: AppColors.primarySurface,
        ),
        _StatTile(
          label: 'Completed',
          value: '$done',
          icon: Icons.check_circle_outlined,
          color: AppColors.statusDone,
          surface: AppColors.statusDoneSurface,
        ),
        _StatTile(
          label: 'In Progress',
          value: '$inProg',
          icon: Icons.timelapse_outlined,
          color: AppColors.statusInProgress,
          surface: AppColors.statusInProgressSurface,
        ),
        _StatTile(
          label: 'Overdue',
          value: '$overdue',
          icon: Icons.warning_amber_outlined,
          color: AppColors.error,
          surface: AppColors.priorityHighSurface,
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color surface;

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.surface,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyEmployees extends StatelessWidget {
  const _EmptyEmployees();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: const Center(
        child: Text(
          'No employees yet.',
          style: TextStyle(color: AppColors.textSecondary),
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
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
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
                reservedSize: 32,
                getTitlesWidget: (v, _) => Text(
                  '${v.toInt()}%',
                  style: const TextStyle(
                      fontSize: 10, color: AppColors.textMuted),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  if (i < 0 || i >= employees.length) return const SizedBox();
                  return Text(
                    employees[i].name.split(' ').first,
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.textSecondary),
                  );
                },
              ),
            ),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            getDrawingHorizontalLine: (_) => const FlLine(
              color: AppColors.border,
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: employees.asMap().entries.map((entry) {
            final rate =
                (stats[entry.value.uid]?.completionRate ?? 0) * 100;
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: rate,
                  color: AppColors.primary,
                  width: 18,
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

  const _EmployeeStatCard({required this.employee, required this.stat});

  @override
  Widget build(BuildContext context) {
    final rate = (stat.completionRate * 100).toStringAsFixed(0);
    final initial =
        employee.name.isNotEmpty ? employee.name[0].toUpperCase() : '?';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primarySurface,
                child: Text(
                  initial,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                employee.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$rate%',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: stat.completionRate,
              backgroundColor: AppColors.border,
              color: AppColors.primary,
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _MiniStat('Assigned', '${stat.totalAssigned}'),
              _MiniStat('Done', '${stat.completed}',
                  color: AppColors.statusDone),
              _MiniStat('On Time', '${stat.onTime}',
                  color: AppColors.primary),
              _MiniStat('Overdue', '${stat.overdue}',
                  color: AppColors.error),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _MiniStat(this.label, this.value, {this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color ?? AppColors.textPrimary,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
                fontSize: 10, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

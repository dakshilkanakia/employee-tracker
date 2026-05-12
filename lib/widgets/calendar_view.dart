import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_colors.dart';
import '../models/task_model.dart';
import 'task_card.dart';

class CalendarView extends StatefulWidget {
  final List<TaskModel> tasks;
  final Map<String, String> assigneeNames;
  final bool isManager;

  const CalendarView({
    super.key,
    required this.tasks,
    this.assigneeNames = const {},
    required this.isManager,
  });

  @override
  State<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
  }

  int get _daysInMonth => DateTime(_month.year, _month.month + 1, 0).day;

  // 0=Sun, 1=Mon … 6=Sat
  int get _startOffset => DateTime(_month.year, _month.month, 1).weekday % 7;

  List<TaskModel> _tasksForDay(int day) {
    final d = DateTime(_month.year, _month.month, day);
    return widget.tasks.where((t) {
      final due = t.dueDate;
      return due.year == d.year && due.month == d.month && due.day == d.day;
    }).toList();
  }

  void _prevMonth() => setState(
        () => _month = DateTime(_month.year, _month.month - 1),
      );

  void _nextMonth() => setState(
        () => _month = DateTime(_month.year, _month.month + 1),
      );

  void _onDayTap(int day) {
    final tasks = _tasksForDay(day);
    if (tasks.isEmpty) return;
    final d = DateTime(_month.year, _month.month, day);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DayTaskSheet(
        day: d,
        tasks: tasks,
        assigneeNames: widget.assigneeNames,
        isManager: widget.isManager,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isCurrentMonth =
        _month.year == now.year && _month.month == now.month;

    return Column(
      children: [
        // Month navigation
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
          child: Row(
            children: [
              IconButton(
                onPressed: _prevMonth,
                icon: const Icon(Icons.chevron_left),
                color: AppColors.textSecondary,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
              Expanded(
                child: Text(
                  DateFormat('MMMM yyyy').format(_month),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              IconButton(
                onPressed: _nextMonth,
                icon: const Icon(Icons.chevron_right),
                color: AppColors.textSecondary,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
              if (!isCurrentMonth)
                TextButton(
                  onPressed: () => setState(() {
                    _month = DateTime(now.year, now.month);
                  }),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Today',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
        // Day-of-week headers
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
          child: Row(
            children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                .map((d) => Expanded(
                      child: Text(
                        d,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ))
                .toList(),
          ),
        ),
        const Divider(height: 1),
        // Calendar grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 0.72,
            ),
            itemCount: _startOffset + _daysInMonth,
            itemBuilder: (_, i) {
              if (i < _startOffset) return const SizedBox.shrink();
              final day = i - _startOffset + 1;
              final isToday = isCurrentMonth && day == now.day;
              final dayTasks = _tasksForDay(day);
              return _DayCell(
                day: day,
                isToday: isToday,
                tasks: dayTasks,
                onTap: () => _onDayTap(day),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  final int day;
  final bool isToday;
  final List<TaskModel> tasks;
  final VoidCallback onTap;

  const _DayCell({
    required this.day,
    required this.isToday,
    required this.tasks,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasTasks = tasks.isNotEmpty;
    final dots = tasks.take(3).toList();
    final extra = tasks.length - dots.length;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: hasTasks
              ? AppColors.primarySurface.withValues(alpha: 0.6)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isToday
                ? AppColors.primary.withValues(alpha: 0.5)
                : hasTasks
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : Colors.transparent,
            width: isToday ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isToday ? AppColors.primary : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$day',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isToday || hasTasks
                        ? FontWeight.w700
                        : FontWeight.w400,
                    color: isToday
                        ? Colors.white
                        : hasTasks
                            ? AppColors.textPrimary
                            : AppColors.textMuted,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            if (hasTasks)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ...dots.map((t) => _TaskDot(task: t)),
                  if (extra > 0)
                    Padding(
                      padding: const EdgeInsets.only(left: 2),
                      child: Text(
                        '+$extra',
                        style: const TextStyle(
                          fontSize: 7,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              )
            else
              const SizedBox(height: 7),
          ],
        ),
      ),
    );
  }
}

class _TaskDot extends StatelessWidget {
  final TaskModel task;
  const _TaskDot({required this.task});

  Color get _color {
    try {
      final hex = task.color.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(
        color: task.isOverdue ? AppColors.error : _color,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _DayTaskSheet extends StatelessWidget {
  final DateTime day;
  final List<TaskModel> tasks;
  final Map<String, String> assigneeNames;
  final bool isManager;

  const _DayTaskSheet({
    required this.day,
    required this.tasks,
    required this.assigneeNames,
    required this.isManager,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.92,
      builder: (ctx, ctrl) => Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.event_outlined,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('EEEE').format(day),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          DateFormat('d MMMM yyyy').format(day),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      '${tasks.length} task${tasks.length == 1 ? '' : 's'}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                controller: ctrl,
                padding: const EdgeInsets.only(top: 8, bottom: 24),
                itemCount: tasks.length,
                itemBuilder: (_, i) => TaskCard(
                  task: tasks[i],
                  assigneeNames: assigneeNames,
                  showAssignees: isManager,
                  onTap: () {
                    final router = GoRouter.of(ctx);
                    Navigator.pop(ctx);
                    router.push(
                      isManager
                          ? '/manager/task/${tasks[i].id}'
                          : '/employee/task/${tasks[i].id}',
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

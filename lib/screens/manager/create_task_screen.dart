import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/task_model.dart';
import '../../models/team_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/team_provider.dart';
import '../../providers/user_provider.dart';

class CreateTaskScreen extends StatefulWidget {
  final String? editTaskId;
  const CreateTaskScreen({super.key, this.editTaskId});

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  List<UserModel> _employees = [];
  List<TeamModel> _teams = [];
  final List<String> _selectedUids = [];
  TaskPriority _priority = TaskPriority.medium;
  Color _color = AppColors.taskColors[0];
  DateTime _dueDate = () {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 9, 0);
  }();
  bool _loadingTask = false;

  bool get _isEditMode => widget.editTaskId != null;

  @override
  void initState() {
    super.initState();
    _loadEmployees();
    _loadTeams();
    if (_isEditMode) _loadExistingTask();
  }

  Future<void> _loadExistingTask() async {
    setState(() => _loadingTask = true);
    final taskProv = context.read<TaskProvider>();
    final task = await taskProv.taskStream(widget.editTaskId!).first;
    if (task == null || !mounted) {
      setState(() => _loadingTask = false);
      return;
    }
    _titleCtrl.text = task.title;
    _descCtrl.text = task.description;
    _notesCtrl.text = task.notes;
    setState(() {
      _priority = task.priority;
      _color = _hexToColor(task.color);
      _dueDate = task.dueDate;
      _selectedUids
        ..clear()
        ..addAll(task.assignedTo);
      _loadingTask = false;
    });
  }

  Color _hexToColor(String hex) {
    try {
      return Color(int.parse('FF${hex.replaceFirst('#', '')}', radix: 16));
    } catch (_) {
      return AppColors.taskColors[0];
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadEmployees() async {
    final auth = context.read<AuthProvider>();
    final userProv = context.read<UserProvider>();
    final emps =
        await userProv.orgEmployeesStream(auth.currentUser!.orgId).first;
    if (mounted) setState(() => _employees = emps);
  }

  Future<void> _loadTeams() async {
    final auth = context.read<AuthProvider>();
    final teamProv = context.read<TeamProvider>();
    final teams =
        await teamProv.teamsStream(auth.currentUser!.orgId).first;
    if (mounted) setState(() => _teams = teams);
  }

  void _toggleTeam(TeamModel team) {
    final memberUids =
        team.memberUids.where((uid) => _employees.any((e) => e.uid == uid)).toList();
    if (memberUids.isEmpty) return;
    final allSelected =
        memberUids.every((uid) => _selectedUids.contains(uid));
    setState(() {
      if (allSelected) {
        _selectedUids.removeWhere(memberUids.contains);
      } else {
        for (final uid in memberUids) {
          if (!_selectedUids.contains(uid)) _selectedUids.add(uid);
        }
      }
    });
  }

  bool _isTeamFullySelected(TeamModel team) {
    final memberUids =
        team.memberUids.where((uid) => _employees.any((e) => e.uid == uid)).toList();
    if (memberUids.isEmpty) return false;
    return memberUids.every(_selectedUids.contains);
  }

  String get _colorHex =>
      '#${_color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dueDate),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );

    setState(() {
      _dueDate = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime?.hour ?? _dueDate.hour,
        pickedTime?.minute ?? _dueDate.minute,
      );
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedUids.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one employee')),
      );
      return;
    }
    final auth = context.read<AuthProvider>();
    final taskProv = context.read<TaskProvider>();

    if (_isEditMode) {
      final existing = await taskProv.taskStream(widget.editTaskId!).first;
      final prunedCompletedBy = (existing?.completedBy ?? [])
          .where(_selectedUids.contains)
          .toList();
      final isGroupTask = _selectedUids.length > 1;
      final allDone = _selectedUids.isNotEmpty &&
          _selectedUids.every(prunedCompletedBy.contains);
      final newStatus = allDone
          ? TaskStatus.completed.value
          : prunedCompletedBy.isNotEmpty
              ? TaskStatus.inProgress.value
              : TaskStatus.pending.value;

      final ok = await taskProv.updateTask(widget.editTaskId!, {
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'assignedTo': _selectedUids,
        'priority': _priority.value,
        'color': _colorHex,
        'dueDate': Timestamp.fromDate(_dueDate),
        'notes': _notesCtrl.text.trim(),
        'isGroupTask': isGroupTask,
        'completedBy': prunedCompletedBy,
        'status': newStatus,
      });
      if (!mounted) return;
      if (ok) {
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(taskProv.error ?? 'Failed to update task')),
        );
      }
    } else {
      final ok = await taskProv.createTask(
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        orgId: auth.currentUser!.orgId,
        assignedTo: _selectedUids,
        assignedBy: auth.currentUser!.uid,
        priority: _priority,
        color: _colorHex,
        dueDate: _dueDate,
        notes: _notesCtrl.text.trim(),
      );
      if (!mounted) return;
      if (ok) {
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(taskProv.error ?? 'Failed to create task')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final taskProv = context.watch<TaskProvider>();
    if (_loadingTask) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(_isEditMode ? 'Edit Task' : 'New Task'),
          backgroundColor: AppColors.background,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Task' : 'New Task'),
        backgroundColor: AppColors.background,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            children: [
              // Title + Description
              _FormCard(
                children: [
                  TextFormField(
                    controller: _titleCtrl,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Task title *',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      fillColor: Colors.transparent,
                    ),
                    validator: (v) => v!.trim().isEmpty ? 'Required' : null,
                  ),
                  const Divider(height: 1),
                  TextFormField(
                    controller: _descCtrl,
                    maxLines: 3,
                    style: const TextStyle(
                        fontSize: 14, color: AppColors.textSecondary),
                    decoration: const InputDecoration(
                      hintText: 'Description (optional)',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      fillColor: Colors.transparent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Priority
              _FormCard(
                children: [
                  _SectionLabel('Priority', Icons.flag_outlined),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    child: Row(
                      children: TaskPriority.values.map((p) {
                        final sel = _priority == p;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () => setState(() => _priority = p),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 10),
                                decoration: BoxDecoration(
                                  color: sel
                                      ? p.color.withValues(alpha: 0.12)
                                      : AppColors.background,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: sel
                                        ? p.color
                                        : AppColors.border,
                                    width: sel ? 1.5 : 1,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      p == TaskPriority.high
                                          ? Icons.keyboard_double_arrow_up
                                          : p == TaskPriority.medium
                                              ? Icons.drag_handle
                                              : Icons.keyboard_double_arrow_down,
                                      color: sel ? p.color : AppColors.textMuted,
                                      size: 18,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      p.label,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: sel
                                            ? FontWeight.w700
                                            : FontWeight.w400,
                                        color: sel
                                            ? p.color
                                            : AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Card color
              _FormCard(
                children: [
                  _SectionLabel('Card Color', Icons.palette_outlined),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: AppColors.taskColors.map((c) {
                        final sel = _color.toARGB32() == c.toARGB32();
                        return GestureDetector(
                          onTap: () => setState(() => _color = c),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: c,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: sel
                                    ? Colors.white
                                    : Colors.transparent,
                                width: 2,
                              ),
                              boxShadow: sel
                                  ? [
                                      BoxShadow(
                                        color: c.withValues(alpha: 0.5),
                                        blurRadius: 6,
                                        spreadRadius: 1,
                                      )
                                    ]
                                  : [],
                            ),
                            child: sel
                                ? const Icon(Icons.check,
                                    color: Colors.white, size: 16)
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Due date
              _FormCard(
                children: [
                  GestureDetector(
                    onTap: _pickDate,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primarySurface,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.calendar_today_outlined,
                                size: 16, color: AppColors.primary),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Due Date & Time',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primarySurface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: AppColors.primary
                                      .withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      DateFormat('d MMM yyyy').format(_dueDate),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    Text(
                                      DateFormat('h:mm a').format(_dueDate),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.primaryLight,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.arrow_drop_down,
                                    size: 16, color: AppColors.primary),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Assign to
              _FormCard(
                children: [
                  _SectionLabel('Assign To', Icons.people_outlined),
                  if (_employees.isEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: const Text(
                        'No employees yet. Share your invite code first.',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 13),
                      ),
                    )
                  else ...[
                    // Team quick-pick row
                    if (_teams.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                        child: Row(
                          children: [
                            const Icon(Icons.group_work_outlined,
                                size: 13, color: AppColors.textMuted),
                            const SizedBox(width: 5),
                            const Text(
                              'Quick pick by team',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: _teams.map((team) {
                            final sel = _isTeamFullySelected(team);
                            return GestureDetector(
                              onTap: () => _toggleTeam(team),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: sel
                                      ? team.displayColor
                                      : team.displayColor.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: sel
                                        ? team.displayColor
                                        : team.displayColor.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      sel ? Icons.check_circle : Icons.group_outlined,
                                      size: 13,
                                      color: sel
                                          ? Colors.white
                                          : team.displayColor,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      team.name,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: sel
                                            ? Colors.white
                                            : team.displayColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const Divider(height: 1),
                      const SizedBox(height: 12),
                    ],
                    // Individual employee chips
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _employees.map((e) {
                          final sel = _selectedUids.contains(e.uid);
                          final initial =
                              e.name.isNotEmpty ? e.name[0].toUpperCase() : '?';
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                if (sel) {
                                  _selectedUids.remove(e.uid);
                                } else {
                                  _selectedUids.add(e.uid);
                                }
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 7),
                              decoration: BoxDecoration(
                                color: sel
                                    ? AppColors.primary
                                    : AppColors.background,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: sel
                                      ? AppColors.primary
                                      : AppColors.border,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircleAvatar(
                                    radius: 10,
                                    backgroundColor: sel
                                        ? Colors.white.withValues(alpha: 0.3)
                                        : AppColors.primarySurface,
                                    child: Text(
                                      initial,
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: sel
                                            ? Colors.white
                                            : AppColors.primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    e.name,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: sel
                                          ? Colors.white
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                  if (sel) ...[
                                    const SizedBox(width: 4),
                                    const Icon(Icons.check,
                                        size: 12, color: Colors.white),
                                  ],
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),

              // Notes
              _FormCard(
                children: [
                  _SectionLabel('Notes', Icons.notes_outlined),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    child: TextFormField(
                      controller: _notesCtrl,
                      maxLines: 3,
                      style: const TextStyle(
                          fontSize: 14, color: AppColors.textSecondary),
                      decoration: const InputDecoration(
                        hintText: 'Additional notes for the employee...',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        fillColor: Colors.transparent,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Submit
              ElevatedButton(
                onPressed: taskProv.submitting ? null : _submit,
                child: taskProv.submitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : Text(_isEditMode ? 'Save Changes' : 'Create Task'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  final List<Widget> children;
  const _FormCard({required this.children});

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final IconData icon;
  const _SectionLabel(this.label, this.icon);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Row(
        children: [
          Icon(icon, size: 15, color: AppColors.textMuted),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

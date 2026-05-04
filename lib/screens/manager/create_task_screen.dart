import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../models/task_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/priority_badge.dart';

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
  final List<String> _selectedUids = [];
  TaskPriority _priority = TaskPriority.medium;
  Color _color = const Color(0xFF2196F3);
  DateTime _dueDate = DateTime.now().add(const Duration(days: 1));

  @override
  void initState() {
    super.initState();
    _loadEmployees();
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
    final emps = await userProv.orgEmployeesStream(auth.currentUser!.orgId).first;
    if (mounted) setState(() => _employees = emps);
  }

  String get _colorHex =>
      '#${_color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  void _pickColor() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Pick task color'),
        content: SingleChildScrollView(
          child: BlockPicker(
            pickerColor: _color,
            availableColors: AppConstants.priorityColors
                .map((hex) => Color(
                    int.parse('FF${hex.replaceFirst('#', '')}', radix: 16)))
                .toList(),
            onColorChanged: (c) => setState(() => _color = c),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          )
        ],
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    final taskProv = context.watch<TaskProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('New Task')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(labelText: 'Task Title *'),
                  validator: (v) => v!.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                const SizedBox(height: 16),
                const Text('Priority',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(
                  children: TaskPriority.values.map((p) {
                    final selected = _priority == p;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _priority = p),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: selected
                                ? p.color.withValues(alpha: 0.15)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: selected ? p.color : Colors.grey[300]!,
                              width: selected ? 2 : 1,
                            ),
                          ),
                          child: PriorityBadge(priority: p),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Task Color',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const Spacer(),
                    GestureDetector(
                      onTap: _pickColor,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _color,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                        onPressed: _pickColor,
                        child: const Text('Change')),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Due Date',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: Text(DateFormat('d MMM yyyy').format(_dueDate)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Assign To *',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                _employees.isEmpty
                    ? Text(
                        'No employees in your organization yet.',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      )
                    : Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: _employees.map((e) {
                          final selected = _selectedUids.contains(e.uid);
                          return FilterChip(
                            label: Text(e.name),
                            selected: selected,
                            onSelected: (v) {
                              setState(() {
                                if (v) {
                                  _selectedUids.add(e.uid);
                                } else {
                                  _selectedUids.remove(e.uid);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notesCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                      labelText: 'Notes (optional)'),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: ElevatedButton(
            onPressed: taskProv.submitting ? null : _submit,
            child: taskProv.submitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : const Text('Create Task'),
          ),
        ),
      ),
    );
  }
}

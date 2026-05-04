import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/task_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/priority_badge.dart';
import '../../widgets/proof_image_viewer.dart';

class EmployeeTaskDetailScreen extends StatelessWidget {
  final String taskId;
  const EmployeeTaskDetailScreen({super.key, required this.taskId});

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
        return _TaskBody(task: task);
      },
    );
  }
}

class _TaskBody extends StatefulWidget {
  final TaskModel task;
  const _TaskBody({required this.task});

  @override
  State<_TaskBody> createState() => _TaskBodyState();
}

class _TaskBodyState extends State<_TaskBody> {
  Map<String, UserModel> _userMap = {};

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final uids = [...widget.task.assignedTo, widget.task.assignedBy];
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

  Future<void> _markInProgress() async {
    await context.read<TaskProvider>().markInProgress(widget.task.id);
  }

  Future<void> _showCompleteSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _CompleteSheet(task: widget.task),
    );
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser!;
    final fmt = DateFormat('d MMM yyyy');
    final alreadyDone = task.hasUserCompleted(user.uid);

    return Scaffold(
      appBar: AppBar(title: const Text('Task Detail')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                border:
                    Border(left: BorderSide(color: _taskColor, width: 4)),
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
                        child: Text(task.title,
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold)),
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
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _Row('Status', task.status.label, Icons.info_outline),
                    _Row(
                        'Assigned by',
                        _userMap[task.assignedBy]?.name ?? '…',
                        Icons.person_outline),
                    _Row('Due date', fmt.format(task.dueDate),
                        Icons.event_outlined,
                        valueColor: task.isOverdue ? Colors.red : null),
                    if (task.notes.isNotEmpty)
                      _Row('Notes', task.notes, Icons.notes_outlined),
                  ],
                ),
              ),
            ),
            if (task.isGroupTask) ...[
              const SizedBox(height: 16),
              const Text('Group Progress',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ...task.assignedTo.map((uid) {
                final name = _userMap[uid]?.name ?? uid;
                final done = task.hasUserCompleted(uid);
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: done ? Colors.green : Colors.grey[300],
                    child: Icon(done ? Icons.check : Icons.person_outline,
                        color: Colors.white, size: 18),
                  ),
                  title: Text(name),
                  trailing: done
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : const Icon(Icons.radio_button_unchecked,
                          color: Colors.grey),
                );
              }),
            ],
            if (task.proofImageUrls.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Proof Images',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ProofImageViewer(imageUrls: task.proofImageUrls),
            ],
            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomNavigationBar: alreadyDone
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (task.status == TaskStatus.pending)
                      OutlinedButton(
                        onPressed: _markInProgress,
                        child: const Text('Mark In Progress'),
                      ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _showCompleteSheet,
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Complete Task'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  const _Row(this.label, this.value, this.icon, {this.valueColor});

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
                  style: TextStyle(
                      color: Colors.grey[600], fontSize: 13))),
          Expanded(
            child: Text(value,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: valueColor)),
          ),
        ],
      ),
    );
  }
}

class _CompleteSheet extends StatefulWidget {
  final TaskModel task;
  const _CompleteSheet({required this.task});

  @override
  State<_CompleteSheet> createState() => _CompleteSheetState();
}

class _CompleteSheetState extends State<_CompleteSheet> {
  final List<XFile> _images = [];
  final _notesCtrl = TextEditingController();
  final _picker = ImagePicker();

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(
        source: source, imageQuality: 80, maxWidth: 1200);
    if (picked != null) {
      setState(() => _images.add(picked));
    }
  }

  Future<void> _submit() async {
    final auth = context.read<AuthProvider>();
    final taskProv = context.read<TaskProvider>();
    final ok = await taskProv.completeTask(
      task: widget.task,
      currentUser: auth.currentUser!,
      proofImages: _images,
    );
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Task marked complete!' : taskProv.error ?? 'Error'),
        backgroundColor: ok ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final taskProv = context.watch<TaskProvider>();
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Complete Task',
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Add photo proof (optional)',
                style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            const SizedBox(height: 16),
            // image grid
            if (_images.isNotEmpty) ...[
              SizedBox(
                height: 80,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _images.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: FutureBuilder<Uint8List>(
                          future: _images[i].readAsBytes(),
                          builder: (_, snap) => snap.hasData
                              ? Image.memory(snap.data!,
                                  width: 80, height: 80, fit: BoxFit.cover)
                              : Container(
                                  width: 80, height: 80,
                                  color: Colors.grey[200]),
                        ),
                      ),
                      Positioned(
                        top: 2,
                        right: 2,
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _images.removeAt(i)),
                          child: const CircleAvatar(
                            radius: 10,
                            backgroundColor: Colors.black54,
                            child: Icon(Icons.close,
                                size: 12, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt_outlined, size: 18),
                  label: const Text('Camera'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_outlined, size: 18),
                  label: const Text('Gallery'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesCtrl,
              decoration: const InputDecoration(
                labelText: 'Completion notes (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: taskProv.submitting ? null : _submit,
                child: taskProv.submitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Mark as Complete'),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

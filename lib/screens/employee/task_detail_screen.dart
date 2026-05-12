import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/comment_model.dart';
import '../../models/task_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/comment_service.dart';
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
  final _commentCtrl = TextEditingController();
  final _commentSvc = CommentService();
  bool _postingComment = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    final uids = [...widget.task.assignedTo, widget.task.assignedBy];
    final map = await context.read<UserProvider>().getUserMap(uids);
    if (mounted) setState(() => _userMap = map);
  }

  Future<void> _postComment() async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;
    final user = context.read<AuthProvider>().currentUser!;
    setState(() => _postingComment = true);
    _commentCtrl.clear();
    await _commentSvc.addComment(
      taskId: widget.task.id,
      authorUid: user.uid,
      authorName: user.name,
      text: text,
    );
    if (mounted) setState(() => _postingComment = false);
  }

  Color get _taskColor {
    try {
      final hex = widget.task.color.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return AppColors.primary;
    }
  }

  Future<void> _markInProgress() async {
    await context.read<TaskProvider>().markInProgress(widget.task.id);
  }

  Future<void> _showCompleteSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Task Detail'),
        backgroundColor: AppColors.background,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
            // Title card
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(width: 4, color: _taskColor),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      task.title,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  PriorityBadge(priority: task.priority),
                                ],
                              ),
                              if (task.description.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  task.description,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Meta info
            _InfoCard(
              children: [
                _MetaRow('Status', task.status.label, Icons.info_outline),
                _MetaRow(
                  'Assigned by',
                  _userMap[task.assignedBy]?.name ?? '…',
                  Icons.person_outline,
                ),
                _MetaRow(
                  'Due date',
                  fmt.format(task.dueDate),
                  Icons.event_outlined,
                  valueColor: task.isOverdue ? AppColors.error : null,
                ),
                if (task.notes.isNotEmpty)
                  _MetaRow('Notes', task.notes, Icons.notes_outlined),
              ],
            ),
            if (task.isGroupTask) ...[
              const SizedBox(height: 16),
              const Text(
                'Group Progress',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              _InfoCard(
                children: task.assignedTo.map((uid) {
                  final name = _userMap[uid]?.name ?? uid;
                  final done = task.hasUserCompleted(uid);
                  final initial =
                      name.isNotEmpty ? name[0].toUpperCase() : '?';
                  return ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor: done
                          ? AppColors.statusDoneSurface
                          : AppColors.border,
                      child: Text(
                        initial,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: done
                              ? AppColors.statusDone
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                    title: Text(name, style: const TextStyle(fontSize: 14)),
                    trailing: done
                        ? const Icon(Icons.check_circle,
                            color: AppColors.statusDone, size: 18)
                        : const Icon(Icons.radio_button_unchecked,
                            color: AppColors.textMuted, size: 18),
                  );
                }).toList(),
              ),
            ],
            if (task.proofImageUrls.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Proof Images',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              ProofImageViewer(imageUrls: task.proofImageUrls),
            ],
            const SizedBox(height: 16),
            const Text(
              'Discussion',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            _CommentsSection(taskId: task.id),
            const SizedBox(height: 16),
          ],
        ),
            ),
          ),
          // Sticky comment input
          _CommentInputBar(
            controller: _commentCtrl,
            posting: _postingComment,
            onPost: _postComment,
          ),
        ],
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
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: const Text('Complete Task'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

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
      child: Column(children: children),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  const _MetaRow(this.label, this.value, this.icon, {this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.textMuted),
          const SizedBox(width: 10),
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: valueColor ?? AppColors.textPrimary,
              ),
            ),
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
    if (picked != null) setState(() => _images.add(picked));
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
        backgroundColor: ok ? AppColors.statusDone : AppColors.error,
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
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Complete Task',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Padding(
              padding: EdgeInsets.only(left: 14),
              child: Text(
                'Add photo proof (optional)',
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 13),
              ),
            ),
            const SizedBox(height: 16),
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
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: AppColors.border,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                        ),
                      ),
                      Positioned(
                        top: 2,
                        right: 2,
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _images.removeAt(i)),
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close,
                                size: 10, color: Colors.white),
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
                  icon: const Icon(Icons.camera_alt_outlined, size: 16),
                  label: const Text('Camera'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 40),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_outlined, size: 16),
                  label: const Text('Gallery'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 40),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesCtrl,
              decoration: const InputDecoration(
                labelText: 'Completion notes (optional)',
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
          ],
        ),
      ),
    );
  }
}

// ── Comments ───────────────────────────────────────────────────────────────────

class _CommentsSection extends StatelessWidget {
  final String taskId;
  const _CommentsSection({required this.taskId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CommentModel>>(
      stream: CommentService().commentsStream(taskId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          ));
        }
        final comments = snap.data ?? [];
        if (comments.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: const Center(
              child: Text(
                'No messages yet. Start the discussion.',
                style:
                    TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ),
          );
        }
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              for (int i = 0; i < comments.length; i++) ...[
                if (i > 0) const Divider(height: 1),
                _CommentTile(comment: comments[i]),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _CommentTile extends StatelessWidget {
  final CommentModel comment;
  const _CommentTile({required this.comment});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('d MMM, h:mm a');
    final initial = comment.authorName.isNotEmpty
        ? comment.authorName[0].toUpperCase()
        : '?';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primarySurface,
            child: Text(
              initial,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.authorName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      fmt.format(comment.createdAt),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  comment.text,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentInputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool posting;
  final VoidCallback onPost;

  const _CommentInputBar({
    required this.controller,
    required this.posting,
    required this.onPost,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(top: BorderSide(color: AppColors.border)),
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 8,
        top: 8,
        bottom: 8 + MediaQuery.of(context).padding.bottom,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onPost(),
              decoration: InputDecoration(
                hintText: 'Add a message…',
                hintStyle: const TextStyle(
                    fontSize: 14, color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.background,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          posting
              ? const SizedBox(
                  width: 40,
                  height: 40,
                  child: Padding(
                    padding: EdgeInsets.all(10),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  onPressed: onPost,
                  icon: const Icon(Icons.send_rounded),
                  color: AppColors.primary,
                  iconSize: 22,
                ),
        ],
      ),
    );
  }
}

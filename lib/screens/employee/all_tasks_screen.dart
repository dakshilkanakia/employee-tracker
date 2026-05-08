import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/task_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/task_card.dart';

class AllTasksScreen extends StatelessWidget {
  const AllTasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final taskProv = context.read<TaskProvider>();
    final userProv = context.read<UserProvider>();
    final orgId = auth.currentUser!.orgId;

    return AppShell(
      navIndex: 1,
      isManager: false,
      title: 'Team Tasks',
      child: StreamBuilder<List<TaskModel>>(
        stream: taskProv.orgTasksStream(orgId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final tasks = snap.data ?? [];
          if (tasks.isEmpty) {
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
                    child: const Icon(Icons.group_outlined,
                        size: 36, color: AppColors.primary),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No team tasks yet',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            );
          }
          final uids = tasks.expand((t) => t.assignedTo).toSet().toList();
          return FutureBuilder<Map<String, UserModel>>(
            future: userProv.getUserMap(uids),
            builder: (context, userSnap) {
              final nameMap = (userSnap.data ?? {})
                  .map((uid, u) => MapEntry(uid, u.name));
              return ListView.builder(
                padding: const EdgeInsets.only(top: 8, bottom: 20),
                itemCount: tasks.length,
                itemBuilder: (_, i) => TaskCard(
                  task: tasks[i],
                  assigneeNames: nameMap,
                  onTap: () =>
                      context.push('/employee/task/${tasks[i].id}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

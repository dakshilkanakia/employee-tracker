import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/task_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/task_card.dart';

class AllTasksScreen extends StatelessWidget {
  const AllTasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final taskProv = context.read<TaskProvider>();
    final userProv = context.read<UserProvider>();
    final orgId = auth.currentUser!.orgId;

    return Scaffold(
      appBar: AppBar(title: const Text('Team Tasks')),
      body: StreamBuilder<List<TaskModel>>(
        stream: taskProv.orgTasksStream(orgId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final tasks = snap.data ?? [];
          if (tasks.isEmpty) {
            return Center(
              child: Text('No tasks yet.',
                  style: TextStyle(color: Colors.grey[600])),
            );
          }
          final uids =
              tasks.expand((t) => t.assignedTo).toSet().toList();
          return FutureBuilder<Map<String, UserModel>>(
            future: userProv.getUserMap(uids),
            builder: (context, userSnap) {
              final nameMap = (userSnap.data ?? {})
                  .map((uid, u) => MapEntry(uid, u.name));
              return ListView.builder(
                padding: const EdgeInsets.only(bottom: 20),
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        onTap: (i) {
          if (i == 0) context.go('/employee');
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

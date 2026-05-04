import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/employee_avatar.dart';

class EmployeeListScreen extends StatelessWidget {
  const EmployeeListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final userProv = context.read<UserProvider>();
    final orgId = auth.currentUser!.orgId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Employees'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push('/manager/notifications'),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/manager/settings'),
          ),
        ],
      ),
      body: StreamBuilder<List<UserModel>>(
        stream: userProv.orgEmployeesStream(orgId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final employees = snap.data ?? [];
          if (employees.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.people_outline, size: 56, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  const Text('No employees yet.'),
                  const SizedBox(height: 8),
                  Text(
                    'Share your invite code with employees.',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => context.push('/manager/settings'),
                    child: const Text('View Invite Code'),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            itemCount: employees.length,
            itemBuilder: (_, i) {
              final emp = employees[i];
              return ListTile(
                leading: EmployeeAvatar(user: emp, radius: 22),
                title: Text(emp.name,
                    style: const TextStyle(fontWeight: FontWeight.w500)),
                subtitle: Text(emp.email,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () =>
                    context.push('/manager/employee/${emp.uid}'),
              );
            },
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        onTap: (i) {
          if (i == 0) context.go('/manager');
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
}

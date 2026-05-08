import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/app_shell.dart';

class EmployeeListScreen extends StatelessWidget {
  const EmployeeListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final userProv = context.read<UserProvider>();
    final orgId = auth.currentUser!.orgId;

    return AppShell(
      navIndex: 1,
      isManager: true,
      title: 'Employees',
      child: StreamBuilder<List<UserModel>>(
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
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: AppColors.primarySurface,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.people_outline,
                        size: 36, color: AppColors.primary),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No employees yet',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Share your invite code with employees.',
                    style: TextStyle(
                        fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => context.push('/manager/settings'),
                    icon: const Icon(Icons.vpn_key_outlined, size: 16),
                    label: const Text('View Invite Code'),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: employees.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final emp = employees[i];
              return _EmployeeCard(emp: emp);
            },
          );
        },
      ),
    );
  }
}

class _EmployeeCard extends StatelessWidget {
  final UserModel emp;
  const _EmployeeCard({required this.emp});

  @override
  Widget build(BuildContext context) {
    final initial =
        emp.name.isNotEmpty ? emp.name[0].toUpperCase() : '?';
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
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: AppColors.primarySurface,
          child: Text(
            initial,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        title: Text(emp.name),
        subtitle: Text(emp.email),
        trailing: const Icon(Icons.chevron_right,
            color: AppColors.textMuted, size: 18),
        onTap: () => context.push('/manager/employee/${emp.uid}'),
      ),
    );
  }
}

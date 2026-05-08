import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/manager_signup_screen.dart';
import '../screens/auth/employee_signup_screen.dart';
import '../screens/manager/dashboard_screen.dart';
import '../screens/manager/create_task_screen.dart';
import '../screens/manager/task_detail_screen.dart';
import '../screens/manager/employee_list_screen.dart';
import '../screens/manager/performance_screen.dart';
import '../screens/manager/settings_screen.dart';
import '../screens/employee/my_tasks_screen.dart';
import '../screens/employee/all_tasks_screen.dart';
import '../screens/employee/task_detail_screen.dart';
import '../screens/employee/employee_settings_screen.dart';
import '../screens/notifications_screen.dart';

// Tab routes use no transition. Push routes (detail screens) use a fade.

Page<void> _tabPage(Widget child) => NoTransitionPage(child: child);

Page<void> _fadePage(Widget child) => CustomTransitionPage(
      child: child,
      transitionDuration: const Duration(milliseconds: 200),
      transitionsBuilder: (_, animation, __, child) =>
          FadeTransition(opacity: animation, child: child),
    );

GoRouter buildRouter(AuthProvider authProvider) {
  return GoRouter(
    refreshListenable: authProvider,
    redirect: (context, state) {
      final isAuthed = authProvider.isAuthenticated;
      final path = state.matchedLocation;
      final isAuthRoute =
          path.startsWith('/login') || path.startsWith('/signup');

      if (!isAuthed && !isAuthRoute) return '/login';
      if (isAuthed && isAuthRoute) {
        return authProvider.currentUser!.isManager ? '/manager' : '/employee';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', redirect: (_, __) => '/login'),
      GoRoute(
          path: '/login',
          pageBuilder: (_, __) => _tabPage(const LoginScreen())),
      GoRoute(
          path: '/signup/manager',
          pageBuilder: (_, __) => _fadePage(const ManagerSignupScreen())),
      GoRoute(
          path: '/signup/employee',
          pageBuilder: (_, __) => _fadePage(const EmployeeSignupScreen())),

      // Manager tab routes — no transition
      GoRoute(
          path: '/manager',
          pageBuilder: (_, __) => _tabPage(const ManagerDashboardScreen())),
      GoRoute(
          path: '/manager/employees',
          pageBuilder: (_, __) => _tabPage(const EmployeeListScreen())),
      GoRoute(
          path: '/manager/performance',
          pageBuilder: (_, __) => _tabPage(const PerformanceScreen())),

      // Manager push routes — fade
      GoRoute(
          path: '/manager/create-task',
          pageBuilder: (_, __) => _fadePage(const CreateTaskScreen())),
      GoRoute(
        path: '/manager/task/:taskId',
        pageBuilder: (_, state) => _fadePage(
            ManagerTaskDetailScreen(taskId: state.pathParameters['taskId']!)),
      ),
      GoRoute(
          path: '/manager/settings',
          pageBuilder: (_, __) => _fadePage(const ManagerSettingsScreen())),
      GoRoute(
          path: '/manager/notifications',
          pageBuilder: (_, __) => _fadePage(const NotificationsScreen())),

      // Employee tab routes — no transition
      GoRoute(
          path: '/employee',
          pageBuilder: (_, __) => _tabPage(const MyTasksScreen())),
      GoRoute(
          path: '/employee/all-tasks',
          pageBuilder: (_, __) => _tabPage(const AllTasksScreen())),
      GoRoute(
          path: '/employee/settings',
          pageBuilder: (_, __) => _tabPage(const EmployeeSettingsScreen())),

      // Employee push routes — fade
      GoRoute(
        path: '/employee/task/:taskId',
        pageBuilder: (_, state) => _fadePage(
            EmployeeTaskDetailScreen(taskId: state.pathParameters['taskId']!)),
      ),
      GoRoute(
          path: '/employee/notifications',
          pageBuilder: (_, __) => _fadePage(const NotificationsScreen())),
    ],
  );
}

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

GoRouter buildRouter(AuthProvider authProvider) {
  return GoRouter(
    refreshListenable: authProvider,
    redirect: (context, state) {
      final isAuthed = authProvider.isAuthenticated;
      final path = state.matchedLocation;
      final isAuthRoute = path.startsWith('/login') ||
          path.startsWith('/signup');

      if (!isAuthed && !isAuthRoute) return '/login';
      if (isAuthed && isAuthRoute) {
        return authProvider.currentUser!.isManager ? '/manager' : '/employee';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', redirect: (_, __) => '/login'),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(
          path: '/signup/manager',
          builder: (_, __) => const ManagerSignupScreen()),
      GoRoute(
          path: '/signup/employee',
          builder: (_, __) => const EmployeeSignupScreen()),

      // Manager routes
      GoRoute(
          path: '/manager',
          builder: (_, __) => const ManagerDashboardScreen()),
      GoRoute(
          path: '/manager/create-task',
          builder: (_, __) => const CreateTaskScreen()),
      GoRoute(
        path: '/manager/task/:taskId',
        builder: (_, state) =>
            ManagerTaskDetailScreen(taskId: state.pathParameters['taskId']!),
      ),
      GoRoute(
          path: '/manager/employees',
          builder: (_, __) => const EmployeeListScreen()),
      GoRoute(
          path: '/manager/performance',
          builder: (_, __) => const PerformanceScreen()),
      GoRoute(
          path: '/manager/settings',
          builder: (_, __) => const ManagerSettingsScreen()),
      GoRoute(
          path: '/manager/notifications',
          builder: (_, __) => const NotificationsScreen()),

      // Employee routes
      GoRoute(path: '/employee', builder: (_, __) => const MyTasksScreen()),
      GoRoute(
          path: '/employee/all-tasks',
          builder: (_, __) => const AllTasksScreen()),
      GoRoute(
        path: '/employee/task/:taskId',
        builder: (_, state) =>
            EmployeeTaskDetailScreen(taskId: state.pathParameters['taskId']!),
      ),
      GoRoute(
          path: '/employee/settings',
          builder: (_, __) => const EmployeeSettingsScreen()),
      GoRoute(
          path: '/employee/notifications',
          builder: (_, __) => const NotificationsScreen()),
    ],
  );
}

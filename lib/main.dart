import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/router.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/task_provider.dart';
import 'providers/team_provider.dart';
import 'providers/user_provider.dart';
import 'services/notification_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(const EmployeeTrackerApp());
}

class EmployeeTrackerApp extends StatefulWidget {
  const EmployeeTrackerApp({super.key});

  @override
  State<EmployeeTrackerApp> createState() => _EmployeeTrackerAppState();
}

class _EmployeeTrackerAppState extends State<EmployeeTrackerApp> {
  late final AuthProvider _authProvider;
  late final TaskProvider _taskProvider;
  late final UserProvider _userProvider;
  late final TeamProvider _teamProvider;

  @override
  void initState() {
    super.initState();
    _authProvider = AuthProvider();
    _taskProvider = TaskProvider();
    _userProvider = UserProvider();
    _teamProvider = TeamProvider();
    _init();
  }

  Future<void> _init() async {
    await _authProvider.init();
    if (_authProvider.currentUser != null) {
      await _userProvider.loadOrg(_authProvider.currentUser!.orgId);
    }
    final notifService = NotificationService();
    await notifService.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authProvider),
        ChangeNotifierProvider.value(value: _taskProvider),
        ChangeNotifierProvider.value(value: _userProvider),
        ChangeNotifierProvider.value(value: _teamProvider),
      ],
      builder: (context, _) {
        final authProvider = context.watch<AuthProvider>();
        final router = buildRouter(authProvider);
        return MaterialApp.router(
          title: 'Employee Tracker',
          theme: AppTheme.theme,
          routerConfig: router,
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

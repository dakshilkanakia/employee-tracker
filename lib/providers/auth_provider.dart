import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../services/user_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final NotificationService _notifService = NotificationService();
  final UserService _userService = UserService();

  UserModel? _currentUser;
  bool _loading = false;
  String? _error;

  UserModel? get currentUser => _currentUser;
  bool get loading => _loading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;

  Future<void> init() async {
    _currentUser = await _authService.getCurrentUserModel();
    if (_currentUser != null) await _updateFcmToken();
    notifyListeners();
  }

  Future<bool> signUpManager({
    required String name,
    required String email,
    required String password,
    required String orgName,
  }) async {
    _setLoading(true);
    try {
      _currentUser = await _authService.signUpManager(
        name: name,
        email: email,
        password: password,
        orgName: orgName,
      );
      await _updateFcmToken();
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signUpEmployee({
    required String name,
    required String email,
    required String password,
    required String inviteCode,
  }) async {
    _setLoading(true);
    try {
      _currentUser = await _authService.signUpEmployee(
        name: name,
        email: email,
        password: password,
        inviteCode: inviteCode,
      );
      await _updateFcmToken();
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    try {
      _currentUser = await _authService.signIn(email: email, password: password);
      await _updateFcmToken();
      _error = null;
      return true;
    } catch (e) {
      _error = _friendlyError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _currentUser = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> _updateFcmToken() async {
    if (_currentUser == null) return;
    final token = await _notifService.getToken();
    if (token != null && token != _currentUser!.fcmToken) {
      await _userService.updateFcmToken(_currentUser!.uid, token);
      _currentUser = _currentUser!.copyWith(fcmToken: token);
    }
  }

  void _setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }

  String _friendlyError(String raw) {
    if (raw.contains('wrong-password') || raw.contains('invalid-credential')) {
      return 'Incorrect email or password.';
    }
    if (raw.contains('user-not-found')) return 'No account found with that email.';
    if (raw.contains('email-already-in-use')) return 'An account already exists with that email.';
    if (raw.contains('weak-password')) return 'Password must be at least 6 characters.';
    return raw.replaceFirst('Exception: ', '');
  }
}

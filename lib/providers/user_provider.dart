import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/organization_model.dart';
import '../services/user_service.dart';
import '../services/org_service.dart';

class UserProvider extends ChangeNotifier {
  final UserService _userService = UserService();
  final OrgService _orgService = OrgService();

  Map<String, UserModel> _userCache = {};
  OrganizationModel? _org;

  OrganizationModel? get org => _org;

  Future<void> loadOrg(String orgId) async {
    _org = await _orgService.getOrg(orgId);
    notifyListeners();
  }

  Stream<OrganizationModel> orgStream(String orgId) =>
      _orgService.orgStream(orgId);

  Stream<List<UserModel>> orgEmployeesStream(String orgId) =>
      _userService.orgEmployeesStream(orgId);

  Future<UserModel?> getUser(String uid) async {
    if (_userCache.containsKey(uid)) return _userCache[uid];
    final user = await _userService.getUser(uid);
    if (user != null) _userCache[uid] = user;
    return user;
  }

  Future<Map<String, UserModel>> getUserMap(List<String> uids) async {
    final result = <String, UserModel>{};
    for (final uid in uids) {
      final user = await getUser(uid);
      if (user != null) result[uid] = user;
    }
    return result;
  }

  Future<String> regenerateInviteCode(String orgId) async {
    final code = await _orgService.regenerateInviteCode(orgId);
    if (_org != null) {
      _org = OrganizationModel(
        id: _org!.id,
        name: _org!.name,
        inviteCode: code,
        createdBy: _org!.createdBy,
        createdAt: _org!.createdAt,
      );
      notifyListeners();
    }
    return code;
  }

  void clearCache() {
    _userCache = {};
    _org = null;
  }
}

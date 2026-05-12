import 'package:flutter/foundation.dart';
import '../models/team_model.dart';
import '../services/team_service.dart';

class TeamProvider extends ChangeNotifier {
  final _service = TeamService();

  Stream<List<TeamModel>> teamsStream(String orgId) =>
      _service.teamsStream(orgId);

  Future<void> createTeam({
    required String orgId,
    required String name,
    required String color,
  }) =>
      _service.createTeam(orgId: orgId, name: name, color: color);

  Future<void> deleteTeam(String orgId, String teamId) =>
      _service.deleteTeam(orgId, teamId);

  Future<void> setMembers(String orgId, String teamId, List<String> uids) =>
      _service.setMembers(orgId, teamId, uids);

  Future<void> renameTeam(String orgId, String teamId, String name) =>
      _service.updateTeam(orgId, teamId, {'name': name});
}

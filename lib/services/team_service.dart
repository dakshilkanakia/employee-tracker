import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/team_model.dart';

class TeamService {
  final _db = FirebaseFirestore.instance;

  CollectionReference _ref(String orgId) =>
      _db.collection('organizations').doc(orgId).collection('teams');

  Stream<List<TeamModel>> teamsStream(String orgId) =>
      _ref(orgId).orderBy('createdAt').snapshots().map(
            (snap) => snap.docs.map((d) => TeamModel.fromDoc(d)).toList(),
          );

  Future<void> createTeam({
    required String orgId,
    required String name,
    required String color,
  }) =>
      _ref(orgId).add({
        'name': name,
        'color': color,
        'memberUids': <String>[],
        'createdAt': FieldValue.serverTimestamp(),
      });

  Future<void> updateTeam(
    String orgId,
    String teamId,
    Map<String, dynamic> data,
  ) =>
      _ref(orgId).doc(teamId).update(data);

  Future<void> deleteTeam(String orgId, String teamId) =>
      _ref(orgId).doc(teamId).delete();

  Future<void> setMembers(String orgId, String teamId, List<String> uids) =>
      _ref(orgId).doc(teamId).update({'memberUids': uids});
}

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/organization_model.dart';

class OrgService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<OrganizationModel?> getOrg(String orgId) async {
    final doc = await _db.collection('organizations').doc(orgId).get();
    if (!doc.exists) return null;
    return OrganizationModel.fromDoc(doc);
  }

  Stream<OrganizationModel> orgStream(String orgId) {
    return _db
        .collection('organizations')
        .doc(orgId)
        .snapshots()
        .map((doc) => OrganizationModel.fromDoc(doc));
  }

  Future<String> regenerateInviteCode(String orgId) async {
    final newCode = _generateInviteCode();
    await _db
        .collection('organizations')
        .doc(orgId)
        .update({'inviteCode': newCode});
    return newCode;
  }

  String _generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    var seed = DateTime.now().millisecondsSinceEpoch;
    final code = StringBuffer();
    for (int i = 0; i < 6; i++) {
      code.write(chars[seed % chars.length]);
      seed = (seed * 1664525 + 1013904223) & 0xFFFFFFFF;
    }
    return code.toString();
  }
}

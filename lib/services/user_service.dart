import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<UserModel?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromDoc(doc);
  }

  Stream<UserModel> userStream(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) => UserModel.fromDoc(doc));
  }

  Future<List<UserModel>> getOrgEmployees(String orgId) async {
    final snap = await _db
        .collection('users')
        .where('orgId', isEqualTo: orgId)
        .where('role', isEqualTo: 'employee')
        .get();
    return snap.docs.map((d) => UserModel.fromDoc(d)).toList();
  }

  Stream<List<UserModel>> orgEmployeesStream(String orgId) {
    return _db
        .collection('users')
        .where('orgId', isEqualTo: orgId)
        .where('role', isEqualTo: 'employee')
        .snapshots()
        .map((snap) => snap.docs.map((d) => UserModel.fromDoc(d)).toList());
  }

  Future<void> updateFcmToken(String uid, String token) async {
    await _db.collection('users').doc(uid).update({'fcmToken': token});
  }
}

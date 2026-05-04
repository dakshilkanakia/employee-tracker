import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';
import '../models/organization_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserModel> signUpManager({
    required String name,
    required String email,
    required String password,
    required String orgName,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = cred.user!.uid;
    final orgId = const Uuid().v4();
    final inviteCode = _generateInviteCode();

    final org = OrganizationModel(
      id: orgId,
      name: orgName,
      inviteCode: inviteCode,
      createdBy: uid,
      createdAt: DateTime.now(),
    );

    final user = UserModel(
      uid: uid,
      name: name,
      email: email,
      role: 'manager',
      orgId: orgId,
      createdAt: DateTime.now(),
    );

    final batch = _db.batch();
    batch.set(_db.collection('organizations').doc(orgId), org.toMap());
    batch.set(_db.collection('users').doc(uid), user.toMap());
    await batch.commit();

    return user;
  }

  Future<UserModel> signUpEmployee({
    required String name,
    required String email,
    required String password,
    required String inviteCode,
  }) async {
    final orgQuery = await _db
        .collection('organizations')
        .where('inviteCode', isEqualTo: inviteCode.toUpperCase())
        .limit(1)
        .get();

    if (orgQuery.docs.isEmpty) {
      throw Exception('Invalid invite code. Please check with your manager.');
    }

    final orgDoc = orgQuery.docs.first;
    final orgId = orgDoc.id;

    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = cred.user!.uid;

    final user = UserModel(
      uid: uid,
      name: name,
      email: email,
      role: 'employee',
      orgId: orgId,
      createdAt: DateTime.now(),
    );

    await _db.collection('users').doc(uid).set(user.toMap());
    return user;
  }

  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
    final uid = _auth.currentUser!.uid;
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) throw Exception('User profile not found.');
    return UserModel.fromDoc(doc);
  }

  Future<void> signOut() => _auth.signOut();

  Future<UserModel?> getCurrentUserModel() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final doc = await _db.collection('users').doc(user.uid).get();
    if (!doc.exists) return null;
    return UserModel.fromDoc(doc);
  }

  String _generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = DateTime.now().millisecondsSinceEpoch;
    final code = StringBuffer();
    var seed = rand;
    for (int i = 0; i < 6; i++) {
      code.write(chars[seed % chars.length]);
      seed = (seed * 1664525 + 1013904223) & 0xFFFFFFFF;
    }
    return code.toString();
  }
}

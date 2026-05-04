import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String role; // 'manager' | 'employee'
  final String orgId;
  final String fcmToken;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.orgId,
    this.fcmToken = '',
    required this.createdAt,
  });

  bool get isManager => role == 'manager';

  factory UserModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      name: d['name'] ?? '',
      email: d['email'] ?? '',
      role: d['role'] ?? 'employee',
      orgId: d['orgId'] ?? '',
      fcmToken: d['fcmToken'] ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'role': role,
        'orgId': orgId,
        'fcmToken': fcmToken,
        'createdAt': FieldValue.serverTimestamp(),
      };

  UserModel copyWith({String? fcmToken}) => UserModel(
        uid: uid,
        name: name,
        email: email,
        role: role,
        orgId: orgId,
        fcmToken: fcmToken ?? this.fcmToken,
        createdAt: createdAt,
      );
}

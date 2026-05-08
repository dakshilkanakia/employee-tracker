import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String role;
  final String orgId;
  final String fcmToken;
  final DateTime createdAt;
  final double? lastLat;
  final double? lastLng;
  final DateTime? locationUpdatedAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.orgId,
    this.fcmToken = '',
    required this.createdAt,
    this.lastLat,
    this.lastLng,
    this.locationUpdatedAt,
  });

  bool get isManager => role == 'manager';
  bool get hasLocation => lastLat != null && lastLng != null;

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
      lastLat: (d['lastLat'] as num?)?.toDouble(),
      lastLng: (d['lastLng'] as num?)?.toDouble(),
      locationUpdatedAt:
          (d['locationUpdatedAt'] as Timestamp?)?.toDate(),
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

  UserModel copyWith({
    String? fcmToken,
    double? lastLat,
    double? lastLng,
    DateTime? locationUpdatedAt,
  }) =>
      UserModel(
        uid: uid,
        name: name,
        email: email,
        role: role,
        orgId: orgId,
        fcmToken: fcmToken ?? this.fcmToken,
        createdAt: createdAt,
        lastLat: lastLat ?? this.lastLat,
        lastLng: lastLng ?? this.lastLng,
        locationUpdatedAt: locationUpdatedAt ?? this.locationUpdatedAt,
      );
}

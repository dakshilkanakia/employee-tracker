import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TeamModel {
  final String id;
  final String name;
  final String color;
  final List<String> memberUids;
  final DateTime createdAt;

  const TeamModel({
    required this.id,
    required this.name,
    required this.color,
    required this.memberUids,
    required this.createdAt,
  });

  Color get displayColor {
    try {
      final hex = color.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return const Color(0xFF4F46E5);
    }
  }

  factory TeamModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return TeamModel(
      id: doc.id,
      name: d['name'] ?? '',
      color: d['color'] ?? '#4F46E5',
      memberUids: List<String>.from(d['memberUids'] ?? []),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'color': color,
        'memberUids': memberUids,
        'createdAt': FieldValue.serverTimestamp(),
      };
}

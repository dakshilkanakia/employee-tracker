import 'package:cloud_firestore/cloud_firestore.dart';

class CommentModel {
  final String id;
  final String authorUid;
  final String authorName;
  final String text;
  final DateTime createdAt;

  const CommentModel({
    required this.id,
    required this.authorUid,
    required this.authorName,
    required this.text,
    required this.createdAt,
  });

  factory CommentModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return CommentModel(
      id: doc.id,
      authorUid: d['authorUid'] ?? '',
      authorName: d['authorName'] ?? 'Unknown',
      text: d['text'] ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

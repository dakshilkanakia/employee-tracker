import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/comment_model.dart';

class CommentService {
  final _db = FirebaseFirestore.instance;

  CollectionReference _ref(String taskId) =>
      _db.collection('tasks').doc(taskId).collection('comments');

  Stream<List<CommentModel>> commentsStream(String taskId) =>
      _ref(taskId).orderBy('createdAt').snapshots().map(
            (snap) => snap.docs.map((d) => CommentModel.fromDoc(d)).toList(),
          );

  Future<void> addComment({
    required String taskId,
    required String authorUid,
    required String authorName,
    required String text,
  }) =>
      _ref(taskId).add({
        'authorUid': authorUid,
        'authorName': authorName,
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
      });
}

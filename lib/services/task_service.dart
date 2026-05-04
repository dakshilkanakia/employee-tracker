import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_model.dart';

class TaskService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _tasks => _db.collection('tasks');

  Future<String> createTask(TaskModel task) async {
    final ref = await _tasks.add(task.toMap());
    return ref.id;
  }

  Future<void> updateTask(String taskId, Map<String, dynamic> data) async {
    await _tasks.doc(taskId).update(data);
  }

  Future<void> deleteTask(String taskId) async {
    await _tasks.doc(taskId).delete();
  }

  Stream<List<TaskModel>> orgTasksStream(String orgId) {
    return _tasks
        .where('orgId', isEqualTo: orgId)
        .orderBy('dueDate')
        .snapshots()
        .map((snap) => snap.docs.map((d) => TaskModel.fromDoc(d)).toList());
  }

  Stream<List<TaskModel>> employeeTasksStream(String orgId, String uid) {
    return _tasks
        .where('orgId', isEqualTo: orgId)
        .where('assignedTo', arrayContains: uid)
        .orderBy('dueDate')
        .snapshots()
        .map((snap) => snap.docs.map((d) => TaskModel.fromDoc(d)).toList());
  }

  Stream<TaskModel?> taskStream(String taskId) {
    return _tasks
        .doc(taskId)
        .snapshots()
        .map((doc) => doc.exists ? TaskModel.fromDoc(doc) : null);
  }

  Future<void> markInProgress(String taskId) async {
    await updateTask(taskId, {'status': TaskStatus.inProgress.value});
  }

  Future<void> employeeCompleteTask({
    required String taskId,
    required String uid,
    required List<String> currentCompletedBy,
    required List<String> assignedTo,
    required List<String> currentProofUrls,
    required List<String> newProofUrls,
  }) async {
    final updatedCompletedBy = [...currentCompletedBy, uid];
    final allDone = updatedCompletedBy.length >= assignedTo.length;
    final updates = <String, dynamic>{
      'completedBy': updatedCompletedBy,
      'proofImageUrls': [...currentProofUrls, ...newProofUrls],
      'status': allDone
          ? TaskStatus.completed.value
          : TaskStatus.inProgress.value,
    };
    if (allDone) {
      updates['completedAt'] = FieldValue.serverTimestamp();
    }
    await updateTask(taskId, updates);
  }
}

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../models/task_model.dart';
import '../models/user_model.dart';
import '../services/task_service.dart';
import '../services/storage_service.dart';

class TaskProvider extends ChangeNotifier {
  final TaskService _taskService = TaskService();
  final StorageService _storageService = StorageService();

  bool _submitting = false;
  String? _error;

  bool get submitting => _submitting;
  String? get error => _error;

  Stream<List<TaskModel>> orgTasksStream(String orgId) =>
      _taskService.orgTasksStream(orgId);

  Stream<List<TaskModel>> employeeTasksStream(String orgId, String uid) =>
      _taskService.employeeTasksStream(orgId, uid);

  Stream<TaskModel?> taskStream(String taskId) =>
      _taskService.taskStream(taskId);

  Future<bool> createTask({
    required String title,
    required String description,
    required String orgId,
    required List<String> assignedTo,
    required String assignedBy,
    required TaskPriority priority,
    required String color,
    required DateTime dueDate,
    String notes = '',
  }) async {
    _setSubmitting(true);
    try {
      final task = TaskModel(
        id: '',
        title: title,
        description: description,
        orgId: orgId,
        assignedTo: assignedTo,
        assignedBy: assignedBy,
        status: TaskStatus.pending,
        priority: priority,
        color: color,
        dateAssigned: DateTime.now(),
        dueDate: dueDate,
        isGroupTask: assignedTo.length > 1,
        completedBy: [],
        notes: notes,
      );
      await _taskService.createTask(task);
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setSubmitting(false);
    }
  }

  Future<bool> updateTask(String taskId, Map<String, dynamic> data) async {
    _setSubmitting(true);
    try {
      await _taskService.updateTask(taskId, data);
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setSubmitting(false);
    }
  }

  Future<bool> deleteTask(String taskId) async {
    _setSubmitting(true);
    try {
      await _taskService.deleteTask(taskId);
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setSubmitting(false);
    }
  }

  Future<bool> markInProgress(String taskId) async {
    try {
      await _taskService.markInProgress(taskId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> completeTask({
    required TaskModel task,
    required UserModel currentUser,
    required List<XFile> proofImages,
  }) async {
    _setSubmitting(true);
    try {
      List<String> newUrls = [];
      if (proofImages.isNotEmpty) {
        newUrls = await _storageService.uploadMultipleProofImages(
          taskId: task.id,
          uid: currentUser.uid,
          files: proofImages,
        );
      }
      await _taskService.employeeCompleteTask(
        taskId: task.id,
        uid: currentUser.uid,
        currentCompletedBy: task.completedBy,
        assignedTo: task.assignedTo,
        currentProofUrls: task.proofImageUrls,
        newProofUrls: newUrls,
      );
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setSubmitting(false);
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setSubmitting(bool v) {
    _submitting = v;
    notifyListeners();
  }
}

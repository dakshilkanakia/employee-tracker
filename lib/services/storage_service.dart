import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadProofImage({
    required String taskId,
    required String uid,
    required File file,
  }) async {
    final ext = file.path.split('.').last;
    final fileName = '${const Uuid().v4()}.$ext';
    final ref = _storage.ref('proof/$taskId/$uid/$fileName');
    final task = await ref.putFile(file);
    return await task.ref.getDownloadURL();
  }

  Future<List<String>> uploadMultipleProofImages({
    required String taskId,
    required String uid,
    required List<File> files,
  }) async {
    final futures = files.map((f) => uploadProofImage(
          taskId: taskId,
          uid: uid,
          file: f,
        ));
    return await Future.wait(futures);
  }
}

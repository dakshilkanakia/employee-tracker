import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadProofImage({
    required String taskId,
    required String uid,
    required XFile file,
  }) async {
    final ext = file.name.split('.').last.toLowerCase();
    final fileName = '${const Uuid().v4()}.$ext';
    final ref = _storage.ref('proof/$taskId/$uid/$fileName');
    final bytes = await file.readAsBytes();
    final task = await ref.putData(bytes, SettableMetadata(contentType: 'image/$ext'));
    return await task.ref.getDownloadURL();
  }

  Future<List<String>> uploadMultipleProofImages({
    required String taskId,
    required String uid,
    required List<XFile> files,
  }) async {
    final futures = files.map((f) => uploadProofImage(
          taskId: taskId,
          uid: uid,
          file: f,
        ));
    return await Future.wait(futures);
  }
}

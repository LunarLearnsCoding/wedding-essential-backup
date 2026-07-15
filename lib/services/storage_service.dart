import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadServiceImage({
    required String vendorId,
    required File file,
  }) async {
    final fileName = DateTime.now().millisecondsSinceEpoch.toString();
    final ref = _storage.ref().child('service_images/$vendorId/$fileName.jpg');
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }
}

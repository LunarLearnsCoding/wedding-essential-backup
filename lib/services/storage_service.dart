import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadServiceImage({
    required String vendorId,
    required XFile image,
  }) async {
    final bytes = await image.readAsBytes();
    final originalName = image.name.trim();
    final dotIndex = originalName.lastIndexOf('.');
    final extension = dotIndex >= 0 ? originalName.substring(dotIndex) : '';
    final uniqueName =
        '${DateTime.now().microsecondsSinceEpoch}_${originalName.hashCode.abs()}$extension';
    final reference = _storage.ref().child(
      'service_images/${vendorId.trim()}/$uniqueName',
    );
    final lowerExtension = extension.toLowerCase();
    final contentType = switch (lowerExtension) {
      '.png' => 'image/png',
      '.webp' => 'image/webp',
      '.gif' => 'image/gif',
      _ => 'image/jpeg',
    };
    return _uploadBytes(
      reference: reference,
      bytes: bytes,
      contentType: contentType,
    );
  }

  Future<String> _uploadBytes({
    required Reference reference,
    required Uint8List bytes,
    required String contentType,
  }) async {
    if (bytes.isEmpty) {
      throw StateError('The selected image is empty. Please choose it again.');
    }

    final snapshot = await reference
        .putData(bytes, SettableMetadata(contentType: contentType))
        .timeout(const Duration(seconds: 40));
    if (snapshot.state != TaskState.success) {
      throw StateError('Firebase Storage did not complete the image upload.');
    }

    return 'gs://${snapshot.ref.bucket}/${snapshot.ref.fullPath}';
  }
}

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const int _maxFirestoreImageBytes = 750 * 1024;

  Future<String> uploadServiceImage({
    required String vendorId,
    required XFile image,
  }) async {
    final bytes = await image.readAsBytes();
    if (bytes.isEmpty) {
      throw StateError('The selected image is empty. Please choose it again.');
    }
    if (bytes.length > _maxFirestoreImageBytes) {
      throw StateError(
        'The selected image is too large after compression. Choose a smaller '
        'image (maximum 750 KB).',
      );
    }

    final originalName = image.name.trim();
    final dotIndex = originalName.lastIndexOf('.');
    final extension = dotIndex >= 0 ? originalName.substring(dotIndex) : '';
    final lowerExtension = extension.toLowerCase();
    final contentType = switch (lowerExtension) {
      '.png' => 'image/png',
      '.webp' => 'image/webp',
      '.gif' => 'image/gif',
      _ => 'image/jpeg',
    };

    final document = _firestore.collection('service_images').doc();
    await document
        .set({
          'vendorId': vendorId.trim(),
          'bytes': Blob(bytes),
          'contentType': contentType,
          'createdAt': FieldValue.serverTimestamp(),
        })
        .timeout(
          const Duration(seconds: 30),
          onTimeout: () => throw TimeoutException(
            'The image upload timed out. Check your connection and try again.',
          ),
        );
    return 'firestore-image://${document.id}';
  }
}

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
    await reference.putData(bytes, SettableMetadata(contentType: contentType));
    return reference.getDownloadURL();
  }

  Future<String> uploadBlogImage({required XFile image}) async {
    final bytes = await image.readAsBytes();
    final originalName = image.name.trim();
    final dotIndex = originalName.lastIndexOf('.');
    final extension = dotIndex >= 0 ? originalName.substring(dotIndex) : '';
    final uniqueName =
        '${DateTime.now().microsecondsSinceEpoch}_${originalName.hashCode.abs()}$extension';
    final reference = _storage.ref().child('blog_images/$uniqueName');
    final lowerExtension = extension.toLowerCase();
    final contentType = switch (lowerExtension) {
      '.png' => 'image/png',
      '.webp' => 'image/webp',
      '.gif' => 'image/gif',
      _ => 'image/jpeg',
    };
    await reference.putData(bytes, SettableMetadata(contentType: contentType));
    return reference.getDownloadURL();
  }
}

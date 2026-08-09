import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

/// Renders the reusable firebase storage image UI component.
class FirebaseStorageImage extends StatefulWidget {
  const FirebaseStorageImage({
    super.key,
    required this.source,
    this.fit = BoxFit.cover,
    this.errorBuilder,
    this.enablePreview = false,
  });

  final String source;
  final BoxFit fit;
  final WidgetBuilder? errorBuilder;
  final bool enablePreview;

  @override
  State<FirebaseStorageImage> createState() => _FirebaseStorageImageState();
}

/// Manages the mutable state, user actions, and UI composition for the related screen.
class _FirebaseStorageImageState extends State<FirebaseStorageImage> {
  Future<Uint8List?>? _imageBytes;

  @override
  void initState() {
    super.initState();
    _loadSource();
  }

  @override
  void didUpdateWidget(covariant FirebaseStorageImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.source != widget.source) _loadSource();
  }

  /// Loads source and updates the visible state.
  void _loadSource() {
    final source = widget.source.trim();
    if (source.startsWith('gs://')) {
      _imageBytes = FirebaseStorage.instance
          .refFromURL(source)
          .getData(20 * 1024 * 1024);
      return;
    }
    if (source.startsWith('firestore-image://')) {
      final imageId = source.substring('firestore-image://'.length);
      _imageBytes = FirebaseFirestore.instance
          .collection('service_images')
          .doc(imageId)
          .get()
          .then((snapshot) => snapshot.data()?['bytes'])
          .then((value) => value is Blob ? value.bytes : null);
      return;
    }
    if (source.startsWith('firestore-profile-image://')) {
      final imageId = source.substring('firestore-profile-image://'.length);
      _imageBytes = FirebaseFirestore.instance
          .collection('profile_images')
          .doc(imageId)
          .get()
          .then((snapshot) => snapshot.data()?['bytes'])
          .then((value) => value is Blob ? value.bytes : null);
      return;
    }
    if (source.startsWith('firestore-blog-image://')) {
      final imageId = source.substring('firestore-blog-image://'.length);
      _imageBytes = FirebaseFirestore.instance
          .collection('blog_images')
          .doc(imageId)
          .get()
          .then((snapshot) => snapshot.data()?['bytes'])
          .then((value) => value is Blob ? value.bytes : null);
      return;
    }
    _imageBytes = null;
  }

  @override
  Widget build(BuildContext context) {
    final image = _buildImage(context);
    if (!widget.enablePreview || widget.source.trim().isEmpty) return image;
    return Semantics(
      button: true,
      label: 'Open image preview',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _showPreview(context),
        child: image,
      ),
    );
  }

  /// Builds the image section of the interface.
  Widget _buildImage(BuildContext context) {
    final source = widget.source.trim();
    if (!source.startsWith('gs://') &&
        !source.startsWith('firestore-image://') &&
        !source.startsWith('firestore-profile-image://') &&
        !source.startsWith('firestore-blog-image://')) {
      return Image.network(
        source,
        fit: widget.fit,
        errorBuilder: (_, __, ___) => _error(context),
      );
    }

    return FutureBuilder<Uint8List?>(
      future: _imageBytes,
      builder: (context, snapshot) {
        if (snapshot.hasError) return _error(context);
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }
        if (!snapshot.hasData) return _error(context);
        return Image.memory(snapshot.data!, fit: widget.fit);
      },
    );
  }

  /// Opens the preview interface for the user.
  Future<void> _showPreview(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (dialogContext) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 5,
                child: Center(
                  child: FirebaseStorageImage(
                    source: widget.source,
                    fit: BoxFit.contain,
                    errorBuilder: widget.errorBuilder,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 18,
              right: 18,
              child: SafeArea(
                child: IconButton.filled(
                  tooltip: 'Close',
                  onPressed: () => Navigator.pop(dialogContext),
                  icon: const Icon(Icons.close),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _error(BuildContext context) {
    return widget.errorBuilder?.call(context) ??
        const Center(child: Icon(Icons.broken_image_outlined));
  }
}

import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class FirebaseStorageImage extends StatefulWidget {
  const FirebaseStorageImage({
    super.key,
    required this.source,
    this.fit = BoxFit.cover,
    this.errorBuilder,
  });

  final String source;
  final BoxFit fit;
  final WidgetBuilder? errorBuilder;

  @override
  State<FirebaseStorageImage> createState() => _FirebaseStorageImageState();
}

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

  void _loadSource() {
    final source = widget.source.trim();
    _imageBytes = source.startsWith('gs://')
        ? FirebaseStorage.instance.refFromURL(source).getData(20 * 1024 * 1024)
        : null;
  }

  @override
  Widget build(BuildContext context) {
    final source = widget.source.trim();
    if (!source.startsWith('gs://')) {
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
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }
        return Image.memory(snapshot.data!, fit: widget.fit);
      },
    );
  }

  Widget _error(BuildContext context) {
    return widget.errorBuilder?.call(context) ??
        const Center(child: Icon(Icons.broken_image_outlined));
  }
}

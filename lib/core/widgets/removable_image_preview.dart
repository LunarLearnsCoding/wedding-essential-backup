import 'package:flutter/material.dart';

/// Renders the reusable removable image preview UI component.
class RemovableImagePreview extends StatelessWidget {
  const RemovableImagePreview({
    super.key,
    required this.image,
    required this.onRemove,
    this.width = 104,
    this.height = 104,
  });

  final Widget image;
  final VoidCallback? onRemove;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(width: width, height: height, child: image),
          ),
          Positioned(
            top: 3,
            right: 3,
            child: IconButton.filled(
              visualDensity: VisualDensity.compact,
              onPressed: onRemove,
              icon: const Icon(Icons.close, size: 16),
            ),
          ),
        ],
      ),
    );
  }
}

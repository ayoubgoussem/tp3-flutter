import 'package:flutter/material.dart';

/// Widget to show image precaching progress
/// Usage: Show this as a SnackBar or overlay after user login
class ImagePrecachingIndicator extends StatefulWidget {
  final VoidCallback onComplete;
  final int totalImages;

  const ImagePrecachingIndicator({
    super.key,
    required this.onComplete,
    required this.totalImages,
  });

  @override
  State<ImagePrecachingIndicator> createState() => _ImagePrecachingIndicatorState();
}

class _ImagePrecachingIndicatorState extends State<ImagePrecachingIndicator> {
  int _cachedImages = 0;

  void incrementProgress() {
    setState(() {
      _cachedImages++;
      if (_cachedImages >= widget.totalImages) {
        widget.onComplete();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.totalImages > 0 
        ? _cachedImages / widget.totalImages 
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.download, size: 20),
              const SizedBox(width: 8),
              Text(
                'Préchargement des images...',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey.shade300,
          ),
          const SizedBox(height: 4),
          Text(
            '$_cachedImages / ${widget.totalImages}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

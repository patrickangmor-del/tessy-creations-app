import 'dart:io';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'photo_viewer_screen.dart';

/// Read-only horizontal strip of photo thumbnails — tap one to view it
/// full-screen (swipeable through the rest). Used where photos are only
/// being looked at, not managed (see [PhotoGalleryField] for that).
class PhotoStrip extends StatelessWidget {
  const PhotoStrip({super.key, required this.photoPaths, this.thumbSize = 72});

  final List<String> photoPaths;
  final double thumbSize;

  @override
  Widget build(BuildContext context) {
    if (photoPaths.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: thumbSize,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: photoPaths.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) => Material(
          color: AppColors.paperDark,
          borderRadius: BorderRadius.circular(4),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PhotoViewerScreen(photoPaths: photoPaths, initialIndex: i),
              ),
            ),
            child: SizedBox(
              width: thumbSize,
              height: thumbSize,
              child: Image.file(File(photoPaths[i]), fit: BoxFit.cover),
            ),
          ),
        ),
      ),
    );
  }
}

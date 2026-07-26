import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../theme/app_theme.dart';
import '../utils/photo_storage.dart';

/// A tappable photo box: shows the current photo (or a placeholder icon),
/// and on tap lets the user choose camera or gallery. Saves the picked
/// image into app storage itself and reports the new path back up.
class PhotoField extends StatelessWidget {
  const PhotoField({
    super.key,
    required this.photoPath,
    required this.onChanged,
    required this.storageSubfolder,
    this.label,
    this.size = 88,
    this.circle = false,
    this.placeholderIcon = Icons.person_outline,
  });

  final String? photoPath;
  final ValueChanged<String?> onChanged;
  final String storageSubfolder;
  final String? label;
  final double size;
  final bool circle;
  final IconData placeholderIcon;

  Future<void> _pick(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            if (photoPath != null)
              ListTile(
                leading: Icon(Icons.delete_outline, color: AppColors.pin),
                title: Text('Remove photo', style: TextStyle(color: AppColors.pin)),
                onTap: () => Navigator.pop(ctx, null),
              ),
          ],
        ),
      ),
    );
    if (source == null) {
      if (photoPath != null) onChanged(null);
      return;
    }
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, maxWidth: 1280, imageQuality: 80);
    if (picked == null) return;
    final savedPath = await savePickedPhoto(picked, storageSubfolder);
    onChanged(savedPath);
  }

  @override
  Widget build(BuildContext context) {
    final shape = circle
        ? const CircleBorder()
        : RoundedRectangleBorder(borderRadius: BorderRadius.circular(4));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: const TextStyle(fontSize: 11, color: AppColors.inkSoft),
          ),
          const SizedBox(height: 4),
        ],
        Material(
          color: AppColors.paperDark,
          shape: shape,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _pick(context),
            child: SizedBox(
              width: size,
              height: size,
              child: photoPath != null
                  ? Image.file(File(photoPath!), fit: BoxFit.cover)
                  : Icon(placeholderIcon, color: AppColors.inkSoft, size: size * 0.35),
            ),
          ),
        ),
      ],
    );
  }
}

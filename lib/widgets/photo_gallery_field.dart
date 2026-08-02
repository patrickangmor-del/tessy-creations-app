import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../theme/app_theme.dart';
import '../utils/photo_storage.dart';
import 'photo_viewer_screen.dart';

/// A horizontal strip of photos with an "add" tile at the end — replaces a
/// single [PhotoField] wherever more than one photo per record makes sense
/// (a customer's reference photos, an order's fabric photos). The caller
/// owns the list; this widget only reports additions/removals back up.
class PhotoGalleryField extends StatelessWidget {
  const PhotoGalleryField({
    super.key,
    required this.photoPaths,
    required this.onChanged,
    required this.storageSubfolder,
    this.label,
  });

  final List<String> photoPaths;
  final ValueChanged<List<String>> onChanged;
  final String storageSubfolder;
  final String? label;

  Future<void> _addPhoto(BuildContext context) async {
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
          ],
        ),
      ),
    );
    if (source == null) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, maxWidth: 1280, imageQuality: 80);
    if (picked == null) return;

    final savedPath = await savePickedPhoto(picked, storageSubfolder);
    onChanged([...photoPaths, savedPath]);
  }

  Future<void> _removePhoto(BuildContext context, int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove this photo?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Remove', style: TextStyle(color: AppColors.pin)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final removedPath = photoPaths[index];
    final updated = [...photoPaths]..removeAt(index);
    onChanged(updated);
    await deleteSavedPhoto(removedPath);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(label!, style: const TextStyle(fontSize: 11, color: AppColors.inkSoft)),
          const SizedBox(height: 4),
        ],
        SizedBox(
          height: 88,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (var i = 0; i < photoPaths.length; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _PhotoThumb(
                    path: photoPaths[i],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PhotoViewerScreen(photoPaths: photoPaths, initialIndex: i),
                      ),
                    ),
                    onRemove: () => _removePhoto(context, i),
                  ),
                ),
              _AddTile(onTap: () => _addPhoto(context)),
            ],
          ),
        ),
      ],
    );
  }
}

class _PhotoThumb extends StatelessWidget {
  const _PhotoThumb({required this.path, required this.onTap, required this.onRemove});

  final String path;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 88,
      height: 88,
      child: Stack(
        children: [
          Positioned.fill(
            child: Material(
              color: AppColors.paperDark,
              borderRadius: BorderRadius.circular(4),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onTap,
                child: Image.file(File(path), fit: BoxFit.cover),
              ),
            ),
          ),
          Positioned(
            top: 2,
            right: 2,
            child: InkWell(
              onTap: onRemove,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                child: const Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddTile extends StatelessWidget {
  const _AddTile({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 88,
      height: 88,
      child: Material(
        color: AppColors.paperDark,
        borderRadius: BorderRadius.circular(4),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: const Center(
            child: Icon(Icons.add_a_photo_outlined, color: AppColors.inkSoft),
          ),
        ),
      ),
    );
  }
}

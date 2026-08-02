import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'ids.dart';

/// Copies a picked photo into the app's private storage (under [subfolder])
/// and returns the saved file's absolute path, so the caller only needs to
/// remember a path string rather than manage files itself.
Future<String> savePickedPhoto(XFile picked, String subfolder) async {
  final docsDir = await getApplicationDocumentsDirectory();
  final targetDir = Directory(p.join(docsDir.path, subfolder));
  if (!await targetDir.exists()) {
    await targetDir.create(recursive: true);
  }
  final ext = p.extension(picked.path).isNotEmpty
      ? p.extension(picked.path)
      : '.jpg';
  final destPath = p.join(targetDir.path, '${generateId()}$ext');
  await File(picked.path).copy(destPath);
  return destPath;
}

/// Deletes a previously saved photo file, ignoring errors (e.g. already gone).
Future<void> deleteSavedPhoto(String? path) async {
  if (path == null) return;
  try {
    final file = File(path);
    if (await file.exists()) await file.delete();
  } catch (_) {
    // Not worth surfacing to the user — the DB record is the source of truth.
  }
}

Future<void> deleteSavedPhotos(List<String> paths) async {
  for (final path in paths) {
    await deleteSavedPhoto(path);
  }
}

import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../data/db/app_database.dart';

const _customerPhotosDir = 'customer_photos';
const _fabricPhotosDir = 'fabric_photos';

/// Thrown when a chosen file isn't a Tessy Creations backup.
class InvalidBackupException implements Exception {
  const InvalidBackupException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Bundles the database and all saved photos into a single zip file (for
/// backup) and can restore the app's data from a previously created one.
/// There's no server involved — the zip is just handed to Android's normal
/// share sheet (e.g. "Save to Drive") or picked back in from wherever the
/// user saved it.
class BackupService {
  /// Builds a zip containing the database file and every saved photo, and
  /// returns its path (in the app's cache directory, ready to share).
  Future<String> createBackupZip() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dbPath = await AppDatabase.instance.filePath();

    // Close the connection first so the file on disk reflects every
    // committed write (SQLite may otherwise keep some data only in a
    // separate journal/WAL file rather than the main one).
    await AppDatabase.instance.close();

    final archive = Archive();
    final dbFile = File(dbPath);
    if (await dbFile.exists()) {
      archive.addFile(
        ArchiveFile(AppDatabase.dbFileName, await dbFile.length(), await dbFile.readAsBytes()),
      );
    }

    for (final subfolder in [_customerPhotosDir, _fabricPhotosDir]) {
      final dir = Directory(p.join(docsDir.path, subfolder));
      if (!await dir.exists()) continue;
      await for (final entity in dir.list()) {
        if (entity is! File) continue;
        final bytes = await entity.readAsBytes();
        archive.addFile(
          ArchiveFile('$subfolder/${p.basename(entity.path)}', bytes.length, bytes),
        );
      }
    }

    final manifest = '{"exportedAt": "${DateTime.now().toIso8601String()}"}';
    archive.addFile(
      ArchiveFile('manifest.json', manifest.length, manifest.codeUnits),
    );

    final zipBytes = ZipEncoder().encode(archive);

    final cacheDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().toIso8601String().replaceAll(RegExp('[:.]'), '-');
    final zipPath = p.join(cacheDir.path, 'tessy-backup-$timestamp.zip');
    await File(zipPath).writeAsBytes(zipBytes);
    return zipPath;
  }

  /// Replaces the current database and photos with the contents of a
  /// previously created backup zip. Throws [InvalidBackupException] if the
  /// file doesn't look like one of ours.
  Future<void> restoreFromZip(String zipPath) async {
    final bytes = await File(zipPath).readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    final dbEntry = archive.files.where((f) => f.name == AppDatabase.dbFileName).firstOrNull;
    if (dbEntry == null) {
      throw const InvalidBackupException(
        "This doesn't look like a Tessy Creations backup file.",
      );
    }

    await AppDatabase.instance.close();

    final dbPath = await AppDatabase.instance.filePath();
    await File(dbPath).writeAsBytes(dbEntry.content);

    final docsDir = await getApplicationDocumentsDirectory();
    for (final subfolder in [_customerPhotosDir, _fabricPhotosDir]) {
      final dir = Directory(p.join(docsDir.path, subfolder));
      // Restoring replaces the photo set entirely, so it matches exactly
      // what's in the backup rather than merging with whatever's already
      // on this device.
      if (await dir.exists()) await dir.delete(recursive: true);
    }

    for (final file in archive.files) {
      if (file.name == AppDatabase.dbFileName || file.name == 'manifest.json') continue;
      if (!file.isFile) continue;
      final outPath = p.join(docsDir.path, file.name);
      final outFile = File(outPath);
      await outFile.parent.create(recursive: true);
      await outFile.writeAsBytes(file.content);
    }
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

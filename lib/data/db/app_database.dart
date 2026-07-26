import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Single shared SQLite database for the whole app.
///
/// Everything lives on-device — there is no server and no sync. Tables are
/// added here as each module is built; [_onCreate] holds the full schema
/// and [_onUpgrade] handles migrating an existing install between versions.
class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  static const _dbName = 'tessy_creations.db';
  static const _dbVersion = 1;

  Database? _db;

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE customers (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        phone TEXT NOT NULL DEFAULT '',
        notes TEXT NOT NULL DEFAULT '',
        photoPath TEXT,
        bust REAL,
        waist REAL,
        hip REAL,
        shoulder REAL,
        sleeveLength REAL,
        fullLength REAL,
        createdAt TEXT NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // No migrations yet — this is version 1.
  }
}

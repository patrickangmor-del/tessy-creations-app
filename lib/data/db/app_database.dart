import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/customer.dart';

/// Single shared SQLite database for the whole app.
///
/// Everything lives on-device — there is no server and no sync. Tables are
/// added here as each module is built; [_onCreate] holds the full schema
/// and [_onUpgrade] handles migrating an existing install between versions.
class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  static const dbFileName = 'tessy_creations.db';
  static const _dbVersion = 5;

  Database? _db;

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  /// The on-disk path of the database file, for backup/restore to copy
  /// directly rather than going through SQL.
  Future<String> filePath() async {
    final dbPath = await getDatabasesPath();
    return p.join(dbPath, dbFileName);
  }

  /// Closes the current connection so the underlying file can be safely
  /// read or replaced (backup/restore). The next call to [database] opens
  /// it again automatically.
  Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  Future<Database> _open() async {
    final path = await filePath();
    return openDatabase(
      path,
      version: _dbVersion,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    final measurementColumns = measurementFields.map((f) => '${f.key} REAL').join(',\n        ');
    await db.execute('''
      CREATE TABLE customers (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        phone TEXT NOT NULL DEFAULT '',
        notes TEXT NOT NULL DEFAULT '',
        photoPaths TEXT,
        $measurementColumns,
        createdAt TEXT NOT NULL
      )
    ''');
    await _createOrdersAndPayments(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    final ordersTableIsNew = oldVersion < 2;
    if (ordersTableIsNew) {
      // Creates the table with every column up to the current schema
      // (including materialsCost and fabricPhotoPaths), so the branches
      // below skip touching it.
      await _createOrdersAndPayments(db);
    } else if (oldVersion < 4) {
      await db.execute('ALTER TABLE orders ADD COLUMN materialsCost REAL');
    }
    if (oldVersion < 3) {
      await _expandMeasurementColumns(db);
    }
    if (oldVersion < 5) {
      await _addPhotoListColumns(db, migrateOrders: !ordersTableIsNew);
    }
  }

  Future<void> _createOrdersAndPayments(Database db) async {
    await db.execute('''
      CREATE TABLE orders (
        id TEXT PRIMARY KEY,
        customerId TEXT NOT NULL,
        dressType TEXT NOT NULL,
        fabricDescription TEXT NOT NULL DEFAULT '',
        fabricPhotoPaths TEXT,
        price REAL NOT NULL,
        materialsCost REAL,
        dueDate TEXT,
        status TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (customerId) REFERENCES customers (id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE payments (
        id TEXT PRIMARY KEY,
        orderId TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        FOREIGN KEY (orderId) REFERENCES orders (id) ON DELETE CASCADE
      )
    ''');
  }

  /// Moves the single `photoPath` / `fabricPhotoPath` columns to
  /// list-valued `photoPaths` / `fabricPhotoPaths` (JSON-encoded), so a
  /// customer or order can have more than one photo. [migrateOrders] is
  /// false when the orders table was just created fresh in this same
  /// upgrade (it already has the new column, nothing to migrate).
  Future<void> _addPhotoListColumns(Database db, {required bool migrateOrders}) async {
    await db.execute('ALTER TABLE customers ADD COLUMN photoPaths TEXT');
    final customerRows = await db.query(
      'customers',
      columns: ['id', 'photoPath'],
      where: 'photoPath IS NOT NULL',
    );
    for (final row in customerRows) {
      await db.update(
        'customers',
        {'photoPaths': jsonEncode([row['photoPath']])},
        where: 'id = ?',
        whereArgs: [row['id']],
      );
    }

    if (!migrateOrders) return;
    await db.execute('ALTER TABLE orders ADD COLUMN fabricPhotoPaths TEXT');
    final orderRows = await db.query(
      'orders',
      columns: ['id', 'fabricPhotoPath'],
      where: 'fabricPhotoPath IS NOT NULL',
    );
    for (final row in orderRows) {
      await db.update(
        'orders',
        {'fabricPhotoPaths': jsonEncode([row['fabricPhotoPath']])},
        where: 'id = ?',
        whereArgs: [row['id']],
      );
    }
  }

  /// Expands the customer measurement set from the original placeholder
  /// six fields to the full standard set Tessy actually measures.
  Future<void> _expandMeasurementColumns(Database db) async {
    // These two already existed under the same name pre-v3.
    const preexisting = {'bust', 'waist'};
    for (final field in measurementFields) {
      if (preexisting.contains(field.key)) continue;
      await db.execute('ALTER TABLE customers ADD COLUMN ${field.key} REAL');
    }
    // The old "hip" field is the same measurement as the new "hips" field,
    // just renamed, so its values carry over directly. The old shoulder /
    // sleeveLength / fullLength fields don't map cleanly to any single new
    // field (e.g. which of the three new sleeve-length variants was a
    // customer's old single value for?), so those are deliberately left
    // alone in their original, now-unused columns rather than guessed at.
    await db.execute('UPDATE customers SET hips = hip');
  }
}

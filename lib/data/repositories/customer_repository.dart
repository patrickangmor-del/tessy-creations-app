import '../db/app_database.dart';
import '../models/customer.dart';
import '../models/measurement_history.dart';

/// All reads/writes to the `customers` table (plus the `measurement_history`
/// table, which only ever exists alongside a customer).
class CustomerRepository {
  Future<List<Customer>> getAll() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('customers', orderBy: 'createdAt DESC');
    return rows.map(Customer.fromMap).toList();
  }

  Future<void> insert(Customer customer) async {
    final db = await AppDatabase.instance.database;
    await db.insert('customers', customer.toMap());
  }

  Future<void> update(Customer customer) async {
    final db = await AppDatabase.instance.database;
    await db.update(
      'customers',
      customer.toMap(),
      where: 'id = ?',
      whereArgs: [customer.id],
    );
  }

  Future<void> delete(String id) async {
    final db = await AppDatabase.instance.database;
    await db.delete('customers', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> insertMeasurementHistory(List<MeasurementHistoryEntry> entries) async {
    if (entries.isEmpty) return;
    final db = await AppDatabase.instance.database;
    final batch = db.batch();
    for (final entry in entries) {
      batch.insert('measurement_history', entry.toMap());
    }
    await batch.commit(noResult: true);
  }

  Future<List<MeasurementHistoryEntry>> getMeasurementHistory(String customerId) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'measurement_history',
      where: 'customerId = ?',
      whereArgs: [customerId],
      orderBy: 'recordedAt DESC',
    );
    return rows.map(MeasurementHistoryEntry.fromMap).toList();
  }
}

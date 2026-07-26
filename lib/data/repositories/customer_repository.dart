import '../db/app_database.dart';
import '../models/customer.dart';

/// All reads/writes to the `customers` table.
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
}

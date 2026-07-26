import '../db/app_database.dart';
import '../models/order.dart';
import '../models/payment.dart';

/// All reads/writes to the `orders` and `payments` tables.
class OrderRepository {
  Future<List<Order>> getAll() async {
    final db = await AppDatabase.instance.database;
    final orderRows = await db.query('orders', orderBy: 'createdAt DESC');
    final paymentRows = await db.query('payments', orderBy: 'date ASC');

    final paymentsByOrder = <String, List<Payment>>{};
    for (final row in paymentRows) {
      final payment = Payment.fromMap(row);
      paymentsByOrder.putIfAbsent(payment.orderId, () => []).add(payment);
    }

    return orderRows
        .map((row) => Order.fromMap(row, payments: paymentsByOrder[row['id']] ?? const []))
        .toList();
  }

  Future<void> insert(Order order) async {
    final db = await AppDatabase.instance.database;
    await db.insert('orders', order.toMap());
    for (final payment in order.payments) {
      await db.insert('payments', payment.toMap());
    }
  }

  /// Updates the order's own columns only — payments are managed separately
  /// via [addPayment], since they're append-only entries in their own table.
  Future<void> update(Order order) async {
    final db = await AppDatabase.instance.database;
    await db.update('orders', order.toMap(), where: 'id = ?', whereArgs: [order.id]);
  }

  Future<void> addPayment(Payment payment) async {
    final db = await AppDatabase.instance.database;
    await db.insert('payments', payment.toMap());
  }

  Future<void> delete(String id) async {
    final db = await AppDatabase.instance.database;
    // Foreign keys are ON (see AppDatabase.onConfigure), so this cascades
    // to the order's payments too.
    await db.delete('orders', where: 'id = ?', whereArgs: [id]);
  }
}

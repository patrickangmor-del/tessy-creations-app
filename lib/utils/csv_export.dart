import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../data/models/customer.dart';
import '../data/models/order.dart';

String _csvField(Object? value) {
  final s = value?.toString() ?? '';
  if (s.contains(',') || s.contains('"') || s.contains('\n')) {
    return '"${s.replaceAll('"', '""')}"';
  }
  return s;
}

String _csvRow(List<Object?> values) => values.map(_csvField).join(',');

/// Writes plain CSV files for customers, orders, and payments to the app's
/// cache directory, for sharing out to a computer or an accountant — a
/// different, more analysis-friendly export than the full backup zip
/// (which is meant for restoring the app itself, not for opening in a
/// spreadsheet).
class CsvExportService {
  Future<List<String>> exportCsvFiles({
    required List<Customer> customers,
    required List<Order> orders,
    required String Function(String customerId) customerName,
  }) async {
    final dir = await getTemporaryDirectory();

    final customersCsv = StringBuffer()
      ..writeln(
        _csvRow(['id', 'name', 'phone', 'notes', 'createdAt', ...measurementFields.map((f) => f.label)]),
      );
    for (final c in customers) {
      customersCsv.writeln(
        _csvRow([
          c.id,
          c.name,
          c.phone,
          c.notes,
          c.createdAt.toIso8601String(),
          ...measurementFields.map((f) => c.measurement(f.key) ?? ''),
        ]),
      );
    }
    final customersPath = p.join(dir.path, 'tessy-customers.csv');
    await File(customersPath).writeAsString(customersCsv.toString());

    final ordersCsv = StringBuffer()
      ..writeln(
        _csvRow([
          'id',
          'customer',
          'dressType',
          'fabricDescription',
          'price',
          'materialsCost',
          'amountPaid',
          'balance',
          'dueDate',
          'status',
          'createdAt',
        ]),
      );
    for (final o in orders) {
      ordersCsv.writeln(
        _csvRow([
          o.id,
          customerName(o.customerId),
          o.dressType,
          o.fabricDescription,
          o.price,
          o.materialsCost ?? '',
          o.amountPaid,
          o.balance,
          o.dueDate ?? '',
          o.status,
          o.createdAt.toIso8601String(),
        ]),
      );
    }
    final ordersPath = p.join(dir.path, 'tessy-orders.csv');
    await File(ordersPath).writeAsString(ordersCsv.toString());

    final paymentsCsv = StringBuffer()..writeln(_csvRow(['customer', 'dressType', 'amount', 'date']));
    for (final o in orders) {
      for (final payment in o.payments) {
        paymentsCsv.writeln(_csvRow([customerName(o.customerId), o.dressType, payment.amount, payment.date]));
      }
    }
    final paymentsPath = p.join(dir.path, 'tessy-payments.csv');
    await File(paymentsPath).writeAsString(paymentsCsv.toString());

    return [customersPath, ordersPath, paymentsPath];
  }
}

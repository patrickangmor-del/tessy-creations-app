import '../data/models/order.dart';
import 'formatters.dart';

/// A plain-text order summary suitable for sharing with a customer (e.g.
/// via WhatsApp or SMS) — no PDF/formatting tooling needed for something
/// this simple.
String buildReceiptText({required Order order, required String customerName}) {
  final buffer = StringBuffer()
    ..writeln('Tessy Creations')
    ..writeln('—')
    ..writeln('Customer: $customerName')
    ..writeln('Item: ${order.dressType}');

  if (order.fabricDescription.isNotEmpty) {
    buffer.writeln('Fabric: ${order.fabricDescription}');
  }

  buffer
    ..writeln('Status: ${order.status}')
    ..writeln('Due: ${formatDate(order.dueDate)}')
    ..writeln('—')
    ..writeln('Price: ${formatMoney(order.price)}')
    ..writeln('Paid: ${formatMoney(order.amountPaid)}')
    ..writeln('Balance due: ${formatMoney(order.balance)}');

  return buffer.toString();
}

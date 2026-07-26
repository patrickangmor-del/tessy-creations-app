import 'package:intl/intl.dart';

final _moneyFormat = NumberFormat.decimalPattern();

/// Formats a number as Naira, e.g. 15000 -> "₦15,000".
String formatMoney(num? amount) => '₦${_moneyFormat.format(amount ?? 0)}';

/// Formats a stored ISO date string (yyyy-MM-dd) as "Jan 5, 2026".
String formatDate(String? isoDate) {
  if (isoDate == null || isoDate.isEmpty) return '—';
  final d = DateTime.parse(isoDate);
  return DateFormat.yMMMd().format(d);
}

/// Today's date as an ISO yyyy-MM-dd string, for storing in the database.
String todayIso() => DateFormat('yyyy-MM-dd').format(DateTime.now());

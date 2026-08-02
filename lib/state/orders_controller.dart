import 'package:flutter/foundation.dart';

import '../data/models/order.dart';
import '../data/models/payment.dart';
import '../data/repositories/order_repository.dart';
import '../utils/formatters.dart';
import '../utils/ids.dart';
import '../utils/photo_storage.dart';

/// Holds the in-memory list of orders and keeps the database in sync,
/// mirroring how [CustomersController] manages customers.
class OrdersController extends ChangeNotifier {
  OrdersController({OrderRepository? repository})
    : _repository = repository ?? OrderRepository();

  final OrderRepository _repository;

  List<Order> _orders = [];
  bool _loading = true;

  List<Order> get orders => _orders;
  bool get loading => _loading;

  List<Order> forCustomer(String customerId) =>
      _orders.where((o) => o.customerId == customerId).toList();

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _orders = await _repository.getAll();
    _loading = false;
    notifyListeners();
  }

  /// Creates an order. If [initialDeposit] is a positive amount, it's
  /// recorded as the first payment, dated today.
  Future<void> add(Order order, {double? initialDeposit}) async {
    final payments = <Payment>[];
    if (initialDeposit != null && initialDeposit > 0) {
      payments.add(
        Payment(id: generateId(), orderId: order.id, amount: initialDeposit, date: todayIso()),
      );
    }
    await _repository.insert(order.copyWith(payments: payments));
    await load();
  }

  Future<void> edit(Order order) async {
    await _repository.update(order);
    await load();
  }

  Future<void> addPayment(String orderId, double amount) async {
    if (amount <= 0) return;
    await _repository.addPayment(
      Payment(id: generateId(), orderId: orderId, amount: amount, date: todayIso()),
    );
    await load();
  }

  Future<void> setStatus(String orderId, String status) async {
    Order? order;
    for (final o in _orders) {
      if (o.id == orderId) {
        order = o;
        break;
      }
    }
    if (order == null) return;
    await _repository.update(order.copyWith(status: status));
    await load();
  }

  Future<void> remove(String id) async {
    Order? order;
    for (final o in _orders) {
      if (o.id == id) {
        order = o;
        break;
      }
    }
    await deleteSavedPhotos(order?.fabricPhotoPaths ?? const []);
    await _repository.delete(id);
    await load();
  }
}

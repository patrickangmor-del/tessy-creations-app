import 'package:flutter/foundation.dart';
import '../data/models/customer.dart';
import '../data/repositories/customer_repository.dart';

/// Holds the in-memory list of customers and keeps the database in sync.
///
/// Screens read this via `context.watch<CustomersController>()` and never
/// talk to [CustomerRepository] directly, so there is one place that knows
/// how to load/add/update/delete a customer.
class CustomersController extends ChangeNotifier {
  CustomersController({CustomerRepository? repository})
    : _repository = repository ?? CustomerRepository();

  final CustomerRepository _repository;

  List<Customer> _customers = [];
  bool _loading = true;

  List<Customer> get customers => _customers;
  bool get loading => _loading;

  Customer? byId(String id) {
    for (final c in _customers) {
      if (c.id == id) return c;
    }
    return null;
  }

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _customers = await _repository.getAll();
    _loading = false;
    notifyListeners();
  }

  Future<void> add(Customer customer) async {
    await _repository.insert(customer);
    await load();
  }

  Future<void> edit(Customer customer) async {
    await _repository.update(customer);
    await load();
  }

  Future<void> remove(String id) async {
    await _repository.delete(id);
    await load();
  }
}

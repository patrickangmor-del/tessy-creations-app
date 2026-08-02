import 'package:flutter/foundation.dart';
import '../data/models/customer.dart';
import '../data/models/measurement_history.dart';
import '../data/repositories/customer_repository.dart';
import '../utils/ids.dart';

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

  /// Adds a new customer, recording every measurement they start with as
  /// the first entry in that field's history.
  Future<void> add(Customer customer) async {
    await _repository.insert(customer);
    await _repository.insertMeasurementHistory(
      _historyEntriesFor(customer, previous: null),
    );
    await load();
  }

  /// Updates a customer, recording a new history entry for any measurement
  /// whose value actually changed.
  Future<void> edit(Customer customer) async {
    final previous = byId(customer.id);
    await _repository.update(customer);
    await _repository.insertMeasurementHistory(
      _historyEntriesFor(customer, previous: previous),
    );
    await load();
  }

  Future<void> remove(String id) async {
    await _repository.delete(id);
    await load();
  }

  Future<List<MeasurementHistoryEntry>> measurementHistory(String customerId) {
    return _repository.getMeasurementHistory(customerId);
  }

  List<MeasurementHistoryEntry> _historyEntriesFor(Customer customer, {Customer? previous}) {
    final now = DateTime.now();
    final entries = <MeasurementHistoryEntry>[];
    for (final field in measurementFields) {
      final value = customer.measurement(field.key);
      if (value == null) continue;
      if (previous != null && previous.measurement(field.key) == value) continue;
      entries.add(
        MeasurementHistoryEntry(
          id: generateId(),
          customerId: customer.id,
          fieldKey: field.key,
          value: value,
          recordedAt: now,
        ),
      );
    }
    return entries;
  }
}

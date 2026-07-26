import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tessy_creations/data/models/customer.dart';
import 'package:tessy_creations/data/repositories/customer_repository.dart';
import 'package:tessy_creations/main.dart';
import 'package:tessy_creations/state/customers_controller.dart';

/// In-memory stand-in for the real sqflite-backed repository, so widget
/// tests don't need a real device database.
class FakeCustomerRepository implements CustomerRepository {
  final List<Customer> _store = [];

  @override
  Future<List<Customer>> getAll() async => List.unmodifiable(_store);

  @override
  Future<void> insert(Customer customer) async => _store.add(customer);

  @override
  Future<void> update(Customer customer) async {
    final i = _store.indexWhere((c) => c.id == customer.id);
    if (i != -1) _store[i] = customer;
  }

  @override
  Future<void> delete(String id) async => _store.removeWhere((c) => c.id == id);
}

CustomersController _fakeController() =>
    CustomersController(repository: FakeCustomerRepository());

void main() {
  testWidgets('App launches showing the four Phase 1 tabs', (tester) async {
    await tester.pumpWidget(TessyApp(customersController: _fakeController()..load()));
    await tester.pumpAndSettle();

    expect(find.text('Tessy Creations'), findsOneWidget);
    expect(find.text('Customers'), findsWidgets);
    expect(find.text('Orders'), findsWidgets);
    expect(find.text('Calendar'), findsWidgets);
    expect(find.text('Finances'), findsWidgets);
  });

  testWidgets('Tapping a nav destination switches tabs', (tester) async {
    await tester.pumpWidget(TessyApp(customersController: _fakeController()..load()));
    await tester.pumpAndSettle();

    expect(find.text('Orders module coming up next'), findsNothing);
    await tester.tap(find.text('Orders'));
    await tester.pumpAndSettle();
    expect(find.text('Orders module coming up next'), findsOneWidget);
  });

  testWidgets('Empty state shows on Customers tab with no customers', (tester) async {
    await tester.pumpWidget(TessyApp(customersController: _fakeController()..load()));
    await tester.pumpAndSettle();

    expect(find.textContaining('No customers yet'), findsOneWidget);
  });

  testWidgets('Adding a customer shows it in the list', (tester) async {
    await tester.pumpWidget(TessyApp(customersController: _fakeController()..load()));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Full name'), 'Amara Obi');
    await tester.scrollUntilVisible(
      find.text('Save customer'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Save customer'));
    await tester.pumpAndSettle();

    expect(find.text('Amara Obi'), findsOneWidget);
  });
}

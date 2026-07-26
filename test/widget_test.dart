import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tessy_creations/data/models/customer.dart';
import 'package:tessy_creations/data/models/order.dart';
import 'package:tessy_creations/data/models/payment.dart';
import 'package:tessy_creations/data/repositories/customer_repository.dart';
import 'package:tessy_creations/data/repositories/order_repository.dart';
import 'package:tessy_creations/main.dart';
import 'package:tessy_creations/state/customers_controller.dart';
import 'package:tessy_creations/state/orders_controller.dart';

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

/// In-memory stand-in for the real sqflite-backed order repository.
class FakeOrderRepository implements OrderRepository {
  final List<Order> _store = [];

  @override
  Future<List<Order>> getAll() async => List.unmodifiable(_store);

  @override
  Future<void> insert(Order order) async => _store.add(order);

  @override
  Future<void> update(Order order) async {
    final i = _store.indexWhere((o) => o.id == order.id);
    if (i != -1) _store[i] = order;
  }

  @override
  Future<void> addPayment(Payment payment) async {
    final i = _store.indexWhere((o) => o.id == payment.orderId);
    if (i != -1) {
      _store[i] = _store[i].copyWith(payments: [..._store[i].payments, payment]);
    }
  }

  @override
  Future<void> delete(String id) async => _store.removeWhere((o) => o.id == id);
}

CustomersController _fakeCustomersController() =>
    CustomersController(repository: FakeCustomerRepository());

OrdersController _fakeOrdersController() =>
    OrdersController(repository: FakeOrderRepository());

Widget _app({CustomersController? customers, OrdersController? orders}) {
  return TessyApp(
    customersController: (customers ?? _fakeCustomersController())..load(),
    ordersController: (orders ?? _fakeOrdersController())..load(),
  );
}

void main() {
  testWidgets('App launches showing the four Phase 1 tabs', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text('Tessy Creations'), findsOneWidget);
    expect(find.text('Customers'), findsWidgets);
    expect(find.text('Orders'), findsWidgets);
    expect(find.text('Calendar'), findsWidgets);
    expect(find.text('Finances'), findsWidgets);
  });

  testWidgets('Tapping a nav destination switches tabs', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text('PAYMENTS COLLECTED BY MONTH'), findsNothing);
    await tester.tap(find.text('Finances'));
    await tester.pumpAndSettle();
    expect(find.text('PAYMENTS COLLECTED BY MONTH'), findsOneWidget);
  });

  testWidgets('Calendar tab shows upcoming pickups for an order with a due date', (tester) async {
    final customers = _fakeCustomersController();
    await customers.load();
    await customers.add(
      Customer(
        id: 'c1',
        name: 'Amara Obi',
        phone: '',
        notes: '',
        photoPath: null,
        bust: null,
        waist: null,
        hip: null,
        shoulder: null,
        sleeveLength: null,
        fullLength: null,
        createdAt: DateTime.now(),
      ),
    );
    final orders = _fakeOrdersController();
    await orders.load();
    final dueDate = DateTime.now().add(const Duration(days: 5));
    final dueIso =
        '${dueDate.year.toString().padLeft(4, '0')}-${dueDate.month.toString().padLeft(2, '0')}-${dueDate.day.toString().padLeft(2, '0')}';
    await orders.add(
      Order(
        id: 'o1',
        customerId: 'c1',
        dressType: 'Gown',
        fabricDescription: '',
        fabricPhotoPath: null,
        price: 500,
        dueDate: dueIso,
        status: orderStatuses.first,
        createdAt: DateTime.now(),
        payments: const [],
      ),
    );

    await tester.pumpWidget(_app(customers: customers, orders: orders));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Calendar'));
    await tester.pumpAndSettle();

    expect(find.text('UPCOMING PICKUPS'), findsOneWidget);
    expect(find.text('Amara Obi'), findsOneWidget);
  });

  testWidgets('Empty state shows on Customers tab with no customers', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.textContaining('No customers yet'), findsOneWidget);
  });

  testWidgets('Adding a customer shows it in the list', (tester) async {
    await tester.pumpWidget(_app());
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

  testWidgets('Orders tab asks for a customer first when there are none', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Orders'));
    await tester.pumpAndSettle();

    expect(find.text('Add a customer first before creating an order.'), findsOneWidget);
  });

  testWidgets('Creating an order shows it with the right balance', (tester) async {
    final customers = _fakeCustomersController();
    await customers.load();
    await customers.add(
      Customer(
        id: 'c1',
        name: 'Amara Obi',
        phone: '',
        notes: '',
        photoPath: null,
        bust: null,
        waist: null,
        hip: null,
        shoulder: null,
        sleeveLength: null,
        fullLength: null,
        createdAt: DateTime.now(),
      ),
    );

    await tester.pumpWidget(_app(customers: customers));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Orders'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Price'), '500');
    await tester.enterText(find.widgetWithText(TextFormField, 'Deposit paid now'), '200');
    await tester.scrollUntilVisible(
      find.text('Save order'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Save order'));
    await tester.pumpAndSettle();

    expect(find.text('Amara Obi'), findsOneWidget);
    expect(find.text('₵500'), findsOneWidget);
    expect(find.text('₵200'), findsOneWidget);
    expect(find.text('₵300'), findsOneWidget); // balance
  });

  testWidgets('Finances tab totals revenue, collected and outstanding', (tester) async {
    final customers = _fakeCustomersController();
    await customers.load();
    await customers.add(
      Customer(
        id: 'c1',
        name: 'Amara Obi',
        phone: '',
        notes: '',
        photoPath: null,
        bust: null,
        waist: null,
        hip: null,
        shoulder: null,
        sleeveLength: null,
        fullLength: null,
        createdAt: DateTime.now(),
      ),
    );
    final orders = _fakeOrdersController();
    await orders.load();
    await orders.add(
      Order(
        id: 'o1',
        customerId: 'c1',
        dressType: 'Gown',
        fabricDescription: '',
        fabricPhotoPath: null,
        price: 500,
        dueDate: null,
        status: orderStatuses.first,
        createdAt: DateTime.now(),
        payments: const [],
      ),
      initialDeposit: 200,
    );

    await tester.pumpWidget(_app(customers: customers, orders: orders));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Finances'));
    await tester.pumpAndSettle();

    expect(find.text('₵500'), findsOneWidget); // revenue
    expect(find.text('₵200'), findsOneWidget); // collected
    expect(find.text('₵300'), findsOneWidget); // outstanding
    expect(find.textContaining('Amara Obi'), findsOneWidget); // recent transaction
  });
}

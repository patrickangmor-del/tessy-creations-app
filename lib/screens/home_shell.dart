import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'customers/customers_list_screen.dart';
import 'orders/orders_list_screen.dart';

/// Bottom-navigation shell for the four Phase 1 modules.
///
/// Each tab body is swapped in below once its module is built; until then
/// [_ComingSoon] is shown as a placeholder so the app still runs end to end.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _tabs = [
    _TabSpec('Customers', Icons.person_outline),
    _TabSpec('Orders', Icons.checkroom_outlined),
    _TabSpec('Calendar', Icons.calendar_month_outlined),
    _TabSpec('Finances', Icons.payments_outlined),
  ];

  static final _bodies = [
    const CustomersListScreen(),
    const OrdersListScreen(),
    const _ComingSoon(title: 'Calendar'),
    const _ComingSoon(title: 'Finances'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.cut, color: AppColors.thread, size: 22),
            SizedBox(width: 8),
            Text('Tessy Creations'),
          ],
        ),
      ),
      body: SafeArea(
        child: IndexedStack(index: _index, children: _bodies),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          for (final tab in _tabs)
            NavigationDestination(icon: Icon(tab.icon), label: tab.label),
        ],
      ),
    );
  }
}

class _TabSpec {
  const _TabSpec(this.label, this.icon);
  final String label;
  final IconData icon;
}

class _ComingSoon extends StatelessWidget {
  const _ComingSoon({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '$title module coming up next',
        style: const TextStyle(color: AppColors.inkSoft),
      ),
    );
  }
}

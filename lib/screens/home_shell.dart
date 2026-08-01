import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'backup/backup_screen.dart';
import 'calendar/calendar_screen.dart';
import 'customers/customers_list_screen.dart';
import 'finances/finances_screen.dart';
import 'orders/orders_list_screen.dart';

/// Bottom-navigation shell for the four Phase 1 modules.
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
    const CalendarScreen(),
    const FinancesScreen(),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.backup_outlined),
            tooltip: 'Backup & Restore',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BackupScreen()),
            ),
          ),
        ],
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

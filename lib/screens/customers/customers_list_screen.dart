import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/customer.dart';
import '../../state/customers_controller.dart';
import '../../theme/app_theme.dart';
import '../../widgets/cut_card.dart';
import '../../widgets/empty_state.dart';
import 'customer_detail_screen.dart';
import 'customer_form_screen.dart';

class CustomersListScreen extends StatefulWidget {
  const CustomersListScreen({super.key});

  @override
  State<CustomersListScreen> createState() => _CustomersListScreenState();
}

class _CustomersListScreenState extends State<CustomersListScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CustomersController>();

    if (controller.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final allCustomers = controller.customers;
    final query = _query.trim().toLowerCase();
    final customers = query.isEmpty
        ? allCustomers
        : allCustomers
              .where(
                (c) =>
                    c.name.toLowerCase().contains(query) ||
                    c.phone.toLowerCase().contains(query),
              )
              .toList();

    return Scaffold(
      body: Column(
        children: [
          if (allCustomers.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'Search by name or phone',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  isDense: true,
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () => setState(() {
                            _searchCtrl.clear();
                            _query = '';
                          }),
                        ),
                ),
              ),
            ),
          Expanded(
            child: allCustomers.isEmpty
                ? const EmptyState(
                    icon: Icons.people_outline,
                    message: 'No customers yet. Tap the + button to add your first one.',
                  )
                : customers.isEmpty
                ? const EmptyState(
                    icon: Icons.search_off,
                    message: 'No customers match that search.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    itemCount: customers.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) => _CustomerTile(customer: customers[i]),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'customers-fab',
        backgroundColor: AppColors.thread,
        foregroundColor: Colors.white,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CustomerFormScreen()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _CustomerTile extends StatelessWidget {
  const _CustomerTile({required this.customer});

  final Customer customer;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => CustomerDetailScreen(customerId: customer.id)),
      ),
      child: CutCard(
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.paperDark,
              backgroundImage: customer.photoPath != null
                  ? FileImage(File(customer.photoPath!))
                  : null,
              child: customer.photoPath == null
                  ? const Icon(Icons.person_outline, color: AppColors.inkSoft)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(customer.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  if (customer.phone.isNotEmpty)
                    Text(
                      customer.phone,
                      style: const TextStyle(fontSize: 12, color: AppColors.inkSoft),
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.inkSoft),
          ],
        ),
      ),
    );
  }
}

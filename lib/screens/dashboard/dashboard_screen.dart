import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/order.dart';
import '../../state/customers_controller.dart';
import '../../state/orders_controller.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/cut_card.dart';
import '../../widgets/section_header.dart';

/// The app's landing tab: an at-a-glance view of what needs attention
/// today, instead of having to check Calendar and Finances separately.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ordersController = context.watch<OrdersController>();
    final customersController = context.watch<CustomersController>();

    if (ordersController.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final orders = ordersController.orders;
    final todayIso = DateTime.now().toIso8601String().substring(0, 10);

    final active = orders.where((o) => o.status != orderStatuses.last).toList();
    final overdue = active.where((o) => o.dueDate != null && o.dueDate!.compareTo(todayIso) < 0).toList()
      ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
    final dueSoon =
        active
            .where((o) => o.dueDate != null && o.dueDate!.compareTo(todayIso) >= 0)
            .toList()
          ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));

    final outstanding = orders.fold<double>(0, (sum, o) => sum + o.balance);

    String nameFor(Order o) => customersController.byId(o.customerId)?.name ?? 'Unknown';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: _StatTile(
                label: 'Outstanding',
                value: formatMoney(outstanding),
                accent: outstanding > 0 ? AppColors.pin : AppColors.thread,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatTile(
                label: 'Overdue',
                value: '${overdue.length}',
                accent: overdue.isEmpty ? AppColors.thread : AppColors.pin,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatTile(label: 'In progress', value: '${active.length}', accent: AppColors.gold),
            ),
          ],
        ),
        if (overdue.isNotEmpty) ...[
          const SizedBox(height: 24),
          const SectionHeader('OVERDUE'),
          const SizedBox(height: 8),
          for (final o in overdue) _OrderRow(order: o, customerName: nameFor(o), overdue: true),
        ],
        const SizedBox(height: 24),
        const SectionHeader('UPCOMING'),
        const SizedBox(height: 8),
        if (dueSoon.isEmpty)
          const Text('Nothing due — you\'re all caught up.', style: TextStyle(color: AppColors.inkSoft))
        else
          for (final o in dueSoon.take(8)) _OrderRow(order: o, customerName: nameFor(o), overdue: false),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value, required this.accent});

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return CutCard(
      accent: accent,
      padding: const EdgeInsets.all(10),
      showIcon: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.inkSoft),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: accent),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _OrderRow extends StatelessWidget {
  const _OrderRow({required this.order, required this.customerName, required this.overdue});

  final Order order;
  final String customerName;
  final bool overdue;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: CutCard(
        accent: overdue ? AppColors.pin : AppColors.dashedBorder,
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$customerName · ${order.dressType}', style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(
                    'Due ${formatDate(order.dueDate)} · ${order.status}',
                    style: TextStyle(fontSize: 12, color: overdue ? AppColors.pin : AppColors.inkSoft),
                  ),
                ],
              ),
            ),
            if (order.balance > 0)
              Text(
                formatMoney(order.balance),
                style: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'monospace'),
              ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/models/order.dart';
import '../../state/customers_controller.dart';
import '../../state/orders_controller.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../utils/receipt.dart';
import '../../widgets/cut_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/photo_strip.dart';
import '../../widgets/status_stepper.dart';
import 'order_form_screen.dart';

class OrdersListScreen extends StatefulWidget {
  const OrdersListScreen({super.key});

  @override
  State<OrdersListScreen> createState() => _OrdersListScreenState();
}

class _OrdersListScreenState extends State<OrdersListScreen> {
  String _filter = 'All';

  @override
  Widget build(BuildContext context) {
    final ordersController = context.watch<OrdersController>();
    final customers = context.watch<CustomersController>().customers;

    if (ordersController.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final orders = _filter == 'All'
        ? ordersController.orders
        : ordersController.orders.where((o) => o.status == _filter).toList();

    return Scaffold(
      // With no customers there can be no orders yet either (deleting a
      // customer cascades to their orders), so show a single explanation
      // instead of stacking it on top of a separate "no orders" state.
      body: customers.isEmpty
          ? const EmptyState(
              icon: Icons.checkroom_outlined,
              message: 'Add a customer first before creating an order.',
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: SizedBox(
                    height: 34,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        for (final s in ['All', ...orderStatuses]) _FilterChip(
                          label: s,
                          selected: _filter == s,
                          onTap: () => setState(() => _filter = s),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: orders.isEmpty
                      ? const EmptyState(
                          icon: Icons.checkroom_outlined,
                          message: 'No orders in this view.',
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: orders.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (context, i) => _OrderCard(order: orders[i]),
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'orders-fab',
        // FloatingActionButton doesn't dim itself for a null onPressed like
        // other Material buttons do, so without this it would look tappable
        // even while disabled.
        backgroundColor: customers.isEmpty ? AppColors.paperDark : AppColors.thread,
        foregroundColor: customers.isEmpty ? AppColors.inkSoft : Colors.white,
        onPressed: customers.isEmpty
            ? null
            : () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderFormScreen())),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.thread,
        labelStyle: TextStyle(color: selected ? Colors.white : AppColors.inkSoft),
        backgroundColor: Colors.transparent,
        side: BorderSide(color: selected ? AppColors.thread : const Color(0xFFD8CBA8)),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final Order order;

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove order?'),
        content: const Text('This removes the order and its payment history. This can\'t be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Remove', style: TextStyle(color: AppColors.pin)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<OrdersController>().remove(order.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final customerName = context.watch<CustomersController>().byId(order.customerId)?.name ?? 'Unknown';

    return CutCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(order.dressType, style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(customerName, style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.share_outlined, size: 20, color: AppColors.inkSoft),
                tooltip: 'Share receipt',
                onPressed: () => Share.share(
                  buildReceiptText(order: order, customerName: customerName),
                ),
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.inkSoft),
                onPressed: () => _confirmDelete(context),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          if (order.fabricDescription.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(order.fabricDescription, style: const TextStyle(fontSize: 13)),
          ],
          if (order.fabricPhotoPaths.isNotEmpty) ...[
            const SizedBox(height: 8),
            PhotoStrip(photoPaths: order.fabricPhotoPaths, thumbSize: 90),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.schedule, size: 13, color: AppColors.inkSoft),
              const SizedBox(width: 4),
              Text('Due ${formatDate(order.dueDate)}', style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
            ],
          ),
          const SizedBox(height: 10),
          StatusStepper(
            status: order.status,
            onChanged: (s) => context.read<OrdersController>().setStatus(order.id, s),
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 8),
          _MoneyRow(label: 'Price', value: order.price),
          _MoneyRow(label: 'Paid', value: order.amountPaid),
          _MoneyRow(
            label: 'Balance',
            value: order.balance,
            emphasize: true,
            color: order.balance > 0 ? AppColors.pin : AppColors.thread,
          ),
          if (order.balance > 0) ...[
            const SizedBox(height: 8),
            _PaymentAdder(orderId: order.id),
          ],
        ],
      ),
    );
  }
}

class _MoneyRow extends StatelessWidget {
  const _MoneyRow({required this.label, required this.value, this.emphasize = false, this.color});

  final String label;
  final double value;
  final bool emphasize;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontWeight: emphasize ? FontWeight.w700 : FontWeight.normal,
      color: color,
      fontFamily: 'monospace',
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(formatMoney(value), style: style),
        ],
      ),
    );
  }
}

class _PaymentAdder extends StatefulWidget {
  const _PaymentAdder({required this.orderId});
  final String orderId;

  @override
  State<_PaymentAdder> createState() => _PaymentAdderState();
}

class _PaymentAdderState extends State<_PaymentAdder> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _add() {
    final amount = double.tryParse(_ctrl.text.trim());
    if (amount == null || amount <= 0) return;
    context.read<OrdersController>().addPayment(widget.orderId, amount);
    _ctrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _ctrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              hintText: 'Record payment',
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
          ),
        ),
        const SizedBox(width: 8),
        OutlinedButton(onPressed: _add, child: const Text('Add')),
      ],
    );
  }
}

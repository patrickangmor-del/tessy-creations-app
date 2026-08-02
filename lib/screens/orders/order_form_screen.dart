import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/order.dart';
import '../../state/customers_controller.dart';
import '../../state/orders_controller.dart';
import '../../theme/app_theme.dart';
import '../../utils/ids.dart';
import '../../widgets/photo_field.dart';

/// A new order. Editing an existing order's core details (customer, dress
/// type, fabric, price, due date, status) isn't needed day-to-day — status
/// moves forward via the stepper and payments are logged as they come in —
/// so this screen only covers creation.
class OrderFormScreen extends StatefulWidget {
  const OrderFormScreen({super.key});

  @override
  State<OrderFormScreen> createState() => _OrderFormScreenState();
}

class _OrderFormScreenState extends State<OrderFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _priceCtrl = TextEditingController();
  final _materialsCostCtrl = TextEditingController();
  final _depositCtrl = TextEditingController();
  final _fabricCtrl = TextEditingController();

  String? _customerId;
  String _dressType = dressTypes.first;
  String? _fabricPhotoPath;
  DateTime? _dueDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final customers = context.read<CustomersController>().customers;
    _customerId = customers.isNotEmpty ? customers.first.id : null;
  }

  @override
  void dispose() {
    _priceCtrl.dispose();
    _materialsCostCtrl.dispose();
    _depositCtrl.dispose();
    _fabricCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _customerId == null) return;
    setState(() => _saving = true);

    final order = Order(
      id: generateId(),
      customerId: _customerId!,
      dressType: _dressType,
      fabricDescription: _fabricCtrl.text.trim(),
      fabricPhotoPath: _fabricPhotoPath,
      price: double.parse(_priceCtrl.text.trim()),
      materialsCost: double.tryParse(_materialsCostCtrl.text.trim()),
      dueDate: _dueDate == null
          ? null
          : '${_dueDate!.year.toString().padLeft(4, '0')}-${_dueDate!.month.toString().padLeft(2, '0')}-${_dueDate!.day.toString().padLeft(2, '0')}',
      status: orderStatuses.first,
      createdAt: DateTime.now(),
      payments: const [],
    );

    final deposit = double.tryParse(_depositCtrl.text.trim());
    await context.read<OrdersController>().add(order, initialDeposit: deposit);

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final customers = context.watch<CustomersController>().customers;

    return Scaffold(
      appBar: AppBar(title: const Text('New order')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<String>(
              initialValue: _customerId,
              decoration: const InputDecoration(labelText: 'Customer'),
              items: [
                for (final c in customers) DropdownMenuItem(value: c.id, child: Text(c.name)),
              ],
              onChanged: (v) => setState(() => _customerId = v),
              validator: (v) => v == null ? 'Choose a customer' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _dressType,
              decoration: const InputDecoration(labelText: 'Dress type'),
              items: [
                for (final d in dressTypes) DropdownMenuItem(value: d, child: Text(d)),
              ],
              onChanged: (v) => setState(() => _dressType = v!),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _fabricCtrl,
              decoration: const InputDecoration(
                labelText: 'Fabric / style notes',
                hintText: 'e.g. royal blue satin, puff sleeves',
              ),
              minLines: 2,
              maxLines: 4,
            ),
            const SizedBox(height: 12),
            PhotoField(
              photoPath: _fabricPhotoPath,
              onChanged: (path) => setState(() => _fabricPhotoPath = path),
              storageSubfolder: 'fabric_photos',
              label: 'Fabric photo (optional)',
              size: 96,
              placeholderIcon: Icons.image_outlined,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _priceCtrl,
                    decoration: const InputDecoration(labelText: 'Price'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      return double.tryParse(v.trim()) == null ? 'Invalid' : null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _depositCtrl,
                    decoration: const InputDecoration(labelText: 'Deposit paid now'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return null;
                      return double.tryParse(v.trim()) == null ? 'Invalid' : null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _materialsCostCtrl,
              decoration: const InputDecoration(
                labelText: 'Materials/fabric cost (optional)',
                hintText: 'What this order cost you to make',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                return double.tryParse(v.trim()) == null ? 'Invalid' : null;
              },
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickDueDate,
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Due date'),
                child: Text(
                  _dueDate == null
                      ? 'No due date set'
                      : '${_dueDate!.year}-${_dueDate!.month.toString().padLeft(2, '0')}-${_dueDate!.day.toString().padLeft(2, '0')}',
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: (customers.isEmpty || _saving) ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check),
              label: const Text('Save order'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.thread,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

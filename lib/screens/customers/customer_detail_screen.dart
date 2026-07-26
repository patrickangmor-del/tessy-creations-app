import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/customer.dart';
import '../../state/customers_controller.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../utils/photo_storage.dart';
import 'customer_form_screen.dart';

class CustomerDetailScreen extends StatelessWidget {
  const CustomerDetailScreen({super.key, required this.customerId});

  final String customerId;

  Future<void> _confirmDelete(BuildContext context, Customer customer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove customer?'),
        content: Text(
          'This removes ${customer.name} and their measurements. This can\'t be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Remove', style: TextStyle(color: AppColors.pin)),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final controller = context.read<CustomersController>();
    await deleteSavedPhoto(customer.photoPath);
    await controller.remove(customer.id);
    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final customer = context.watch<CustomersController>().byId(customerId);

    if (customer == null) {
      // Was deleted (e.g. from another screen) while this one was open.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Navigator.canPop(context)) Navigator.pop(context);
      });
      return const Scaffold(body: SizedBox.shrink());
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(customer.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => CustomerFormScreen(customer: customer)),
            ),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: AppColors.pin),
            onPressed: () => _confirmDelete(context, customer),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: CircleAvatar(
              radius: 55,
              backgroundColor: AppColors.paperDark,
              backgroundImage: customer.photoPath != null
                  ? FileImage(File(customer.photoPath!))
                  : null,
              child: customer.photoPath == null
                  ? const Icon(Icons.person_outline, size: 40, color: AppColors.inkSoft)
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          if (customer.phone.isNotEmpty)
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.phone, size: 14, color: AppColors.inkSoft),
                  const SizedBox(width: 4),
                  Text(customer.phone, style: const TextStyle(color: AppColors.inkSoft)),
                ],
              ),
            ),
          const SizedBox(height: 20),
          const Text(
            'MEASUREMENTS (INCHES)',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.inkSoft,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.6,
            children: [
              for (final f in measurementFields)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.cream,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.dashedBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(f.label, style: const TextStyle(fontSize: 10, color: AppColors.inkSoft)),
                      Text(
                        customer.measurement(f.key)?.toString() ?? '—',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (customer.notes.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text(
              'NOTES',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.inkSoft,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(customer.notes),
          ],
          const SizedBox(height: 20),
          Text(
            'Customer since ${formatDate(customer.createdAt.toIso8601String().substring(0, 10))}',
            style: const TextStyle(fontSize: 12, color: AppColors.inkSoft),
          ),
        ],
      ),
    );
  }
}

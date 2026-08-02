import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/customer.dart';
import '../../data/models/measurement_history.dart';
import '../../state/customers_controller.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/empty_state.dart';

class MeasurementHistoryScreen extends StatelessWidget {
  const MeasurementHistoryScreen({super.key, required this.customerId, required this.customerName});

  final String customerId;
  final String customerName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('$customerName — measurement history')),
      body: FutureBuilder<List<MeasurementHistoryEntry>>(
        future: context.read<CustomersController>().measurementHistory(customerId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final entries = snapshot.data!;
          if (entries.isEmpty) {
            return const EmptyState(
              icon: Icons.history,
              message: 'No measurement changes recorded yet. Every time a measurement '
                  'is added or edited, it\'ll show up here.',
            );
          }

          final byField = <String, List<MeasurementHistoryEntry>>{};
          for (final entry in entries) {
            byField.putIfAbsent(entry.fieldKey, () => []).add(entry);
          }

          final fieldsWithHistory = [
            for (final field in measurementFields)
              if (byField.containsKey(field.key)) field,
          ];

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: fieldsWithHistory.length,
            separatorBuilder: (_, _) => const SizedBox(height: 16),
            itemBuilder: (context, i) {
              final field = fieldsWithHistory[i];
              final fieldEntries = byField[field.key]!; // newest first
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(field.label, style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  for (final entry in fieldEntries)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Text(
                            '${entry.value}"',
                            style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            formatDate(entry.recordedAt.toIso8601String().substring(0, 10)),
                            style: const TextStyle(fontSize: 12, color: AppColors.inkSoft),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

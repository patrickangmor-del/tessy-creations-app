import 'package:flutter/material.dart';

import '../data/models/customer.dart';
import 'section_header.dart';

/// Lays out every measurement field grouped into its section (general
/// fields first with no heading, then Skirt/Slit Length, Sleeve Length,
/// Around Arm each under their own small heading). [fieldBuilder] supplies
/// the widget for a single field — a text input on the form screen, a
/// read-only value tile on the detail screen — so this widget only owns
/// the grouping and the responsive column count.
class MeasurementSections extends StatelessWidget {
  const MeasurementSections({super.key, required this.fieldBuilder});

  final Widget Function(MeasurementField field) fieldBuilder;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final crossAxisCount = width > 700 ? 3 : 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final section in measurementSections) ...[
          if (section.title != null) ...[
            SectionHeader(section.title!.toUpperCase()),
            const SizedBox(height: 8),
          ],
          GridView.count(
            crossAxisCount: crossAxisCount,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.2,
            children: [for (final field in section.fields) fieldBuilder(field)],
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The small uppercase heading used above a section of content (e.g.
/// "MEASUREMENTS", "UPCOMING"), with a short purple accent bar so section
/// breaks are easy to scan at a glance. [trailing] sits at the far end of
/// the same row, for a section-level action like "History".
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.label, {super.key, this.trailing});

  final String label;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final heading = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 3,
          height: 12,
          decoration: BoxDecoration(
            color: AppColors.thread,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: sectionLabelStyle),
      ],
    );

    if (trailing == null) return heading;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [heading, trailing!],
    );
  }
}

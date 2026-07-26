import 'package:flutter/material.dart';

import '../data/models/order.dart';
import '../theme/app_theme.dart';

/// The "Getting Fabrics → … → Delivered" progress row. Tapping a dot jumps
/// straight to that stage — useful since a stage can occasionally be
/// skipped or corrected, not just advanced one step at a time.
class StatusStepper extends StatelessWidget {
  const StatusStepper({super.key, required this.status, required this.onChanged});

  final String status;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final currentIndex = orderStatuses.indexOf(status);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (var i = 0; i < orderStatuses.length; i++) ...[
              GestureDetector(
                onTap: () => onChanged(orderStatuses[i]),
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i <= currentIndex ? AppColors.thread : AppColors.paperDark,
                    border: Border.all(
                      color: i <= currentIndex ? AppColors.threadDark : const Color(0xFFC9BC98),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              if (i != orderStatuses.length - 1)
                Expanded(
                  child: Container(
                    height: 0,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: i < currentIndex ? AppColors.threadDark : const Color(0xFFC9BC98),
                          width: 1.5,
                          style: BorderStyle.solid,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          status,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.threadDark),
        ),
      ],
    );
  }
}

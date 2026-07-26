import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A card with a dashed border and a small scissors accent, matching the
/// "cut fabric swatch" look from the original design.
class CutCard extends StatelessWidget {
  const CutCard({
    super.key,
    required this.child,
    this.accent,
    this.padding,
    this.showIcon = true,
  });

  final Widget child;
  final Color? accent;
  final EdgeInsetsGeometry? padding;

  /// The corner scissors icon pokes slightly outside the card's own bounds,
  /// which reads fine with normal card spacing but can overlap a neighbor
  /// when several cards sit close together (e.g. three in a tight row) —
  /// set this to false in that situation.
  final bool showIcon;

  @override
  Widget build(BuildContext context) {
    final color = accent ?? AppColors.dashedBorder;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: padding ?? const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.cream,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color, width: 1.5),
          ),
          child: child,
        ),
        if (showIcon)
          Positioned(
            top: -8,
            left: -8,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: AppColors.paper,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.cut, size: 13, color: color),
            ),
          ),
      ],
    );
  }
}

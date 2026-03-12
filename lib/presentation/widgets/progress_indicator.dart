// lib/presentation/widgets/progress_indicator.dart

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Simple linear progress indicator
class AppProgressIndicator extends StatelessWidget {
  final double value;
  final double? height;
  final Color? backgroundColor;
  final Color? valueColor;
  final bool showPercentage;

  const AppProgressIndicator({
    super.key,
    required this.value,
    this.height,
    this.backgroundColor,
    this.valueColor,
    this.showPercentage = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fgColor = valueColor ?? AppColors.primary;
    final bgColor =
        backgroundColor ??
        (isDark ? Colors.white.withOpacity(0.1) : Colors.grey[200]!);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular((height ?? 8) / 2),
          child: LinearProgressIndicator(
            value: value,
            minHeight: height ?? 8,
            backgroundColor: bgColor,
            valueColor: AlwaysStoppedAnimation<Color>(fgColor),
          ),
        ),
        if (showPercentage) ...[
          const SizedBox(height: 4),
          Text(
            '${(value * 100).toInt()}%',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: fgColor,
            ),
          ),
        ],
      ],
    );
  }
}

/// Simple circular progress
class CircularProgress extends StatelessWidget {
  final double value;
  final double? size;
  final double strokeWidth;
  final Color? color;
  final bool showPercentage;

  const CircularProgress({
    super.key,
    required this.value,
    this.size,
    this.strokeWidth = 4,
    this.color,
    this.showPercentage = false,
  });

  @override
  Widget build(BuildContext context) {
    final fgColor = color ?? AppColors.primary;
    final effectiveSize = size ?? 60;

    return SizedBox(
      width: effectiveSize,
      height: effectiveSize,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            value: value,
            strokeWidth: strokeWidth,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(fgColor),
          ),
          if (showPercentage)
            Center(
              child: Text(
                '${(value * 100).toInt()}%',
                style: TextStyle(
                  fontSize: effectiveSize * 0.25,
                  fontWeight: FontWeight.bold,
                  color: fgColor,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

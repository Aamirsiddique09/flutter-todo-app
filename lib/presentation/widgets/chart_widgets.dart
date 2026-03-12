// lib/presentation/widgets/chart_widgets.dart

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Simple line chart using CustomPaint - minimal memory
class SimpleLineChart extends StatelessWidget {
  final List<double> data;
  final Color? color;
  final double height;

  const SimpleLineChart({
    super.key,
    required this.data,
    this.color,
    this.height = 100,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(double.infinity, height),
      painter: _LineChartPainter(data: data, color: color ?? AppColors.primary),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<double> data;
  final Color color;

  _LineChartPainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = color.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();

    final stepX = size.width / (data.length - 1);
    final maxY = data.reduce((a, b) => a > b ? a : b);

    path.moveTo(0, size.height - (data[0] / maxY) * size.height);
    fillPath.moveTo(0, size.height);
    fillPath.lineTo(0, size.height - (data[0] / maxY) * size.height);

    for (int i = 1; i < data.length; i++) {
      final x = i * stepX;
      final y = size.height - (data[i] / maxY) * size.height;
      path.lineTo(x, y);
      fillPath.lineTo(x, y);
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Bar chart - minimal memory
class SimpleBarChart extends StatelessWidget {
  final List<double> data;
  final List<String>? labels;
  final Color? color;
  final double height;

  const SimpleBarChart({
    super.key,
    required this.data,
    this.labels,
    this.color,
    this.height = 120,
  });

  @override
  Widget build(BuildContext context) {
    final maxValue = data.reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(data.length, (index) {
          final barHeight = (data[index] / maxValue) * (height - 20);

          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  height: barHeight,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: color ?? AppColors.primary,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                  ),
                ),
                if (labels != null && index < labels!.length) ...[
                  const SizedBox(height: 4),
                  Text(
                    labels![index],
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ],
            ),
          );
        }),
      ),
    );
  }
}

/// Circular progress chart
class CircularChart extends StatelessWidget {
  final double value; // 0.0 to 1.0
  final double? size;
  final Color? color;
  final Widget? center;

  const CircularChart({
    super.key,
    required this.value,
    this.size,
    this.color,
    this.center,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveSize = size ?? 80;
    final fgColor = color ?? AppColors.primary;

    return SizedBox(
      width: effectiveSize,
      height: effectiveSize,
      child: CustomPaint(
        painter: _CircularChartPainter(value: value, color: fgColor),
        child: center != null ? Center(child: center!) : null,
      ),
    );
  }
}

class _CircularChartPainter extends CustomPainter {
  final double value;
  final Color color;

  _CircularChartPainter({required this.value, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    final bgPaint = Paint()
      ..color = Colors.grey[200]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;

    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.5708, // -90 degrees
      value * 6.28318, // 2 * pi
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Weekly activity chart (used in dashboard)
class WeeklyChart extends StatelessWidget {
  final List<double> values; // 7 values

  const WeeklyChart({super.key, required this.values})
    : assert(values.length == 7);

  @override
  Widget build(BuildContext context) {
    return SimpleLineChart(data: values, height: 60);
  }
}

/// Simple pie chart
class SimplePieChart extends StatelessWidget {
  final List<double> values;
  final List<Color>? colors;
  final double? size;

  const SimplePieChart({
    super.key,
    required this.values,
    this.colors,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    final total = values.reduce((a, b) => a + b);
    final effectiveColors =
        colors ??
        [
          AppColors.primary,
          AppColors.accentPurple,
          Colors.green,
          Colors.orange,
        ];

    return SizedBox(
      width: size ?? 100,
      height: size ?? 100,
      child: CustomPaint(
        painter: _PieChartPainter(
          values: values,
          total: total,
          colors: effectiveColors,
        ),
      ),
    );
  }
}

class _PieChartPainter extends CustomPainter {
  final List<double> values;
  final double total;
  final List<Color> colors;

  _PieChartPainter({
    required this.values,
    required this.total,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    double startAngle = -1.5708; // -90 degrees

    for (int i = 0; i < values.length; i++) {
      final sweepAngle = (values[i] / total) * 6.28318;

      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.fill;

      canvas.drawArc(rect, startAngle, sweepAngle, true, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

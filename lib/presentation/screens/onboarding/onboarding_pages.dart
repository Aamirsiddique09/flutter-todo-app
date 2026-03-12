// lib/presentation/screens/onboarding/onboarding_page.dart

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../widgets/glass_container.dart';

/// Data class for onboarding page content
class OnboardingPageData {
  final String title;
  final String description;
  final Widget illustration;

  const OnboardingPageData({
    required this.title,
    required this.description,
    required this.illustration,
  });
}

/// Individual onboarding page widget
class OnboardingPage extends StatelessWidget {
  final OnboardingPageData data;
  final Animation<double>? fadeAnimation;

  const OnboardingPage({super.key, required this.data, this.fadeAnimation});

  @override
  Widget build(BuildContext context) {
    Widget content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration
          SizedBox(height: 300, child: data.illustration),

          const SizedBox(height: 40),

          // Title
          Text(
            data.title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          // Description
          Text(
            data.description,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );

    if (fadeAnimation != null) {
      return FadeTransition(opacity: fadeAnimation!, child: content);
    }

    return content;
  }
}

// ==================== ILLUSTRATIONS ====================

/// Progress tracking illustration with animated chart
class ProgressIllustration extends StatefulWidget {
  const ProgressIllustration({super.key});

  @override
  State<ProgressIllustration> createState() => _ProgressIllustrationState();
}

class _ProgressIllustrationState extends State<ProgressIllustration>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Weekly Activity',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[400],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  AnimatedBuilder(
                    animation: _progressAnimation,
                    builder: (context, child) {
                      return Text(
                        '+${(85 * _progressAnimation.value).toInt()}%',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                        ),
                      );
                    },
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.trending_up, color: AppColors.primary),
              ),
            ],
          ),
          const Spacer(),
          // Animated Chart
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return CustomPaint(
                size: const Size(double.infinity, 100),
                painter: _ChartPainter(progress: _progressAnimation.value),
              );
            },
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN']
                .map(
                  (day) => Text(
                    day,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[500],
                    ),
                  ),
                )
                .toList(),
          ),
          const Spacer(),
          // Floating Badge with pulse animation
          _PulsingBadge(),
        ],
      ),
    );
  }
}

class _PulsingBadge extends StatefulWidget {
  @override
  State<_PulsingBadge> createState() => _PulsingBadgeState();
}

class _PulsingBadgeState extends State<_PulsingBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.05), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.05, end: 1.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GlassContainer(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            borderRadius: BorderRadius.circular(8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'ON TRACK',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ChartPainter extends CustomPainter {
  final double progress;

  _ChartPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.primary.withOpacity(0.3),
          AppColors.primary.withOpacity(0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final path = Path();
    final points = [
      Offset(0, size.height * 0.7),
      Offset(size.width * 0.15, size.height * 0.7),
      Offset(size.width * 0.15, size.height * 0.2),
      Offset(size.width * 0.3, size.height * 0.2),
      Offset(size.width * 0.3, size.height * 0.4),
      Offset(size.width * 0.45, size.height * 0.4),
      Offset(size.width * 0.45, size.height * 0.1),
      Offset(size.width * 0.6, size.height * 0.1),
      Offset(size.width * 0.6, size.height * 0.6),
      Offset(size.width * 0.75, size.height * 0.6),
      Offset(size.width * 0.75, size.height * 0.3),
      Offset(size.width * 0.9, size.height * 0.3),
      Offset(size.width * 0.9, size.height * 0.5),
      Offset(size.width * progress, size.height * 0.5),
    ];

    if (points.length < 2) return;

    path.moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    // Fill area
    final fillPath = Path.from(path);
    fillPath.lineTo(size.width * progress, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();
    canvas.drawPath(fillPath, fillPaint);

    // Line
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Productivity/Trophy illustration
class ProductivityIllustration extends StatefulWidget {
  const ProductivityIllustration({super.key});

  @override
  State<ProductivityIllustration> createState() =>
      _ProductivityIllustrationState();
}

class _ProductivityIllustrationState extends State<ProductivityIllustration>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(
      begin: -0.1,
      end: 0.1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      width: double.infinity,
      child: Center(
        child: AnimatedBuilder(
          animation: _rotationAnimation,
          builder: (context, child) {
            return Transform.rotate(
              angle: _rotationAnimation.value,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.amber.withOpacity(0.3),
                      Colors.orange.withOpacity(0.3),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.emoji_events,
                  size: 80,
                  color: Colors.amber,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Organization illustration with floating cards
class OrganizationIllustration extends StatefulWidget {
  const OrganizationIllustration({super.key});

  @override
  State<OrganizationIllustration> createState() =>
      _OrganizationIllustrationState();
}

class _OrganizationIllustrationState extends State<OrganizationIllustration>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;

  final List<Map<String, dynamic>> _cards = [
    {'icon': Icons.check_circle, 'color': Colors.green, 'delay': 0},
    {'icon': Icons.calendar_today, 'color': AppColors.primary, 'delay': 200},
    {'icon': Icons.folder, 'color': Colors.orange, 'delay': 400},
    {'icon': Icons.star, 'color': Colors.purple, 'delay': 600},
  ];

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      _cards.length,
      (index) => AnimationController(
        duration: const Duration(seconds: 2),
        vsync: this,
      ),
    );

    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: _cards[i]['delay'] as int), () {
        if (mounted) _controllers[i].repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        GlassContainer(width: 200, height: 200, child: Container()),
        Positioned(
          top: 20,
          left: 20,
          child: _FloatingCard(
            icon: _cards[0]['icon'] as IconData,
            color: _cards[0]['color'] as Color,
            controller: _controllers[0],
          ),
        ),
        Positioned(
          top: 40,
          right: 20,
          child: _FloatingCard(
            icon: _cards[1]['icon'] as IconData,
            color: _cards[1]['color'] as Color,
            controller: _controllers[1],
          ),
        ),
        Positioned(
          bottom: 40,
          left: 30,
          child: _FloatingCard(
            icon: _cards[2]['icon'] as IconData,
            color: _cards[2]['color'] as Color,
            controller: _controllers[2],
          ),
        ),
        Positioned(
          bottom: 20,
          right: 30,
          child: _FloatingCard(
            icon: _cards[3]['icon'] as IconData,
            color: _cards[3]['color'] as Color,
            controller: _controllers[3],
          ),
        ),
      ],
    );
  }
}

class _FloatingCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final AnimationController controller;

  const _FloatingCard({
    required this.icon,
    required this.color,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final value = controller.value;
        final yOffset = value * 10;
        final scale = 1 + (value * 0.05);

        return Transform.translate(
          offset: Offset(0, yOffset),
          child: Transform.scale(
            scale: scale,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: color, size: 24),
            ),
          ),
        );
      },
    );
  }
}

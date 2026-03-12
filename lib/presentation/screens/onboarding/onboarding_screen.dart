// lib/presentation/screens/onboarding/onboarding_screen.dart

import 'package:flutter/material.dart';
import 'package:todolist/presentation/screens/onboarding/onboarding_pages.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/local_storage.dart';
import '../../widgets/animated_button.dart';
import '../auth/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late final List<OnboardingPageData> _pagesData;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _pagesData = const [
      OnboardingPageData(
        title: 'Track your progress',
        description:
            'Visualize your journey with real-time data and insightful growth charts.',
        illustration: ProgressIllustration(),
      ),
      OnboardingPageData(
        title: 'Stay productive',
        description:
            'Achieve your goals and manage your tasks efficiently with our intuitive tools.',
        illustration: ProductivityIllustration(),
      ),
      OnboardingPageData(
        title: 'Organize everything',
        description:
            'Keep all your tasks, projects, and schedules in one beautiful place.',
        illustration: OrganizationIllustration(),
      ),
    ];

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _nextPage() async {
    if (_currentPage < _pagesData.length - 1) {
      await _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    } else {
      // Mark onboarding as complete
      await localStorage.setBool('onboarding_complete', true);

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    }
  }

  void _skip() async {
    await localStorage.setBool('onboarding_complete', true);

    if (mounted) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Skip Button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: AnimatedOpacity(
                  opacity: _currentPage == _pagesData.length - 1 ? 0 : 1,
                  duration: const Duration(milliseconds: 200),
                  child: TextButton(
                    onPressed: _skip,
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Page Content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                  _fadeController.reset();
                  _fadeController.forward();
                },
                itemCount: _pagesData.length,
                itemBuilder: (context, index) {
                  return OnboardingPage(
                    data: _pagesData[index],
                    fadeAnimation: _currentPage == index
                        ? _fadeAnimation
                        : null,
                  );
                },
              ),
            ),

            // Bottom Controls
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Progress Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pagesData.length, (index) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? AppColors.primary
                              : (isDark ? Colors.white24 : Colors.black12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 32),

                  // Next Button with animation
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: AnimatedButton(
                      key: ValueKey<String>(
                        _currentPage == _pagesData.length - 1
                            ? 'get_started'
                            : 'next',
                      ),
                      text: _currentPage == _pagesData.length - 1
                          ? 'Get Started'
                          : 'Next Step',
                      icon: _currentPage == _pagesData.length - 1
                          ? Icons.check
                          : Icons.arrow_forward,
                      onPressed: _nextPage,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}// lib/presentation/screens/onboarding/onboarding_screen.dart


// lib/app.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/constants/app_colors.dart';
import 'core/constants/app_theme.dart';
import 'presentation/screens/splash/splash_screen.dart';
import 'presentation/screens/onboarding/onboarding_screen.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/home/dashboard_screen.dart';
import 'presentation/screens/projects/projects_screen.dart';
import 'presentation/screens/calendar/calendar_screen.dart';
import 'presentation/screens/profile/profile_screen.dart';

class TaskFlowApp extends StatefulWidget {
  const TaskFlowApp({super.key});

  @override
  State<TaskFlowApp> createState() => _TaskFlowAppState();
}

class _TaskFlowAppState extends State<TaskFlowApp> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _setSystemUIOverlay();
  }

  void _setSystemUIOverlay() {
    final brightness = WidgetsBinding.instance.window.platformBrightness;
    final isDark =
        _themeMode == ThemeMode.dark ||
        (_themeMode == ThemeMode.system && brightness == Brightness.dark);

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: isDark
            ? AppColors.backgroundDark
            : AppColors.backgroundLight,
        systemNavigationBarIconBrightness: isDark
            ? Brightness.light
            : Brightness.dark,
      ),
    );
  }

  void toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light
          ? ThemeMode.dark
          : ThemeMode.light;
    });
    _setSystemUIOverlay();
  }

  @override
  Widget build(BuildContext context) {
    return _AppInheritedWidget(
      toggleTheme: toggleTheme,
      child: MaterialApp(
        title: 'TaskFlow',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: _themeMode,
        initialRoute: AppRoutes.splash,
        routes: {
          AppRoutes.splash: (_) => const SplashScreen(),
          AppRoutes.onboarding: (_) => const OnboardingScreen(),
          AppRoutes.login: (_) => const LoginScreen(),
          AppRoutes.dashboard: (_) => const DashboardScreen(),
          AppRoutes.projects: (_) => const ProjectsScreen(),
          AppRoutes.calendar: (_) => const CalendarScreen(),
          AppRoutes.profile: (_) => const ProfileScreen(),
        },
      ),
    );
  }
}

// Simple inherited widget - just for theme toggle
class _AppInheritedWidget extends InheritedWidget {
  final VoidCallback toggleTheme;

  const _AppInheritedWidget({required this.toggleTheme, required super.child});

  static _AppInheritedWidget of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_AppInheritedWidget>()!;
  }

  @override
  bool updateShouldNotify(_AppInheritedWidget old) => false;
}

// Route names
class AppRoutes {
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const dashboard = '/dashboard';
  static const projects = '/projects';
  static const calendar = '/calendar';
  static const profile = '/profile';
}

// Simple extension
extension AppContext on BuildContext {
  VoidCallback get toggleTheme => _AppInheritedWidget.of(this).toggleTheme;
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
}

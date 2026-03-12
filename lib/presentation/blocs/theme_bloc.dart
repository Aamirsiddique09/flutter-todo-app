// lib/presentation/blocs/theme_bloc.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../services/local_storage.dart';

/// Theme state class
class ThemeState {
  final ThemeMode themeMode;
  final bool followSystem;

  const ThemeState({
    this.themeMode = ThemeMode.system,
    this.followSystem = true,
  });

  ThemeState copyWith({ThemeMode? themeMode, bool? followSystem}) {
    return ThemeState(
      themeMode: themeMode ?? this.themeMode,
      followSystem: followSystem ?? this.followSystem,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ThemeState &&
          runtimeType == other.runtimeType &&
          themeMode == other.themeMode &&
          followSystem == other.followSystem;

  @override
  int get hashCode => themeMode.hashCode ^ followSystem.hashCode;
}

/// Theme events
abstract class ThemeEvent {}

class InitializeThemeEvent extends ThemeEvent {}

class SetThemeModeEvent extends ThemeEvent {
  final ThemeMode themeMode;
  SetThemeModeEvent(this.themeMode);
}

class ToggleThemeEvent extends ThemeEvent {}

class SetFollowSystemEvent extends ThemeEvent {
  final bool followSystem;
  SetFollowSystemEvent(this.followSystem);
}

class SystemThemeChangedEvent extends ThemeEvent {
  final Brightness brightness;
  SystemThemeChangedEvent(this.brightness);
}

/// Theme BLoC for reactive theme management
class ThemeBloc {
  final LocalStorageService _storage;

  // State
  ThemeState _currentState = const ThemeState();

  // Streams
  final _stateController = StreamController<ThemeState>.broadcast();
  final _eventController = StreamController<ThemeEvent>();

  // Public streams
  Stream<ThemeState> get stateStream => _stateController.stream;
  ThemeState get currentState => _currentState;

  // System brightness observer
  Brightness? _lastSystemBrightness;

  ThemeBloc({LocalStorageService? storage})
    : _storage = storage ?? localStorage {
    _eventController.stream.listen(_mapEventToState);
    _initSystemObserver();
  }

  void _initSystemObserver() {
    // Listen to platform brightness changes
    final window = SchedulerBinding.instance.window;
    _lastSystemBrightness = window.platformBrightness;

    window.onPlatformBrightnessChanged = () {
      final newBrightness = window.platformBrightness;
      if (newBrightness != _lastSystemBrightness) {
        _lastSystemBrightness = newBrightness;
        add(SystemThemeChangedEvent(newBrightness));
      }
    };
  }

  void add(ThemeEvent event) {
    _eventController.add(event);
  }

  void _mapEventToState(ThemeEvent event) async {
    if (event is InitializeThemeEvent) {
      await _handleInitialize();
    } else if (event is SetThemeModeEvent) {
      _handleSetThemeMode(event);
    } else if (event is ToggleThemeEvent) {
      _handleToggleTheme();
    } else if (event is SetFollowSystemEvent) {
      _handleSetFollowSystem(event);
    } else if (event is SystemThemeChangedEvent) {
      _handleSystemThemeChanged(event);
    }
  }

  Future<void> _handleInitialize() async {
    final savedTheme = _storage.getString(LocalStorageKeys.themeMode);
    final followSystem = _storage.getBool('follow_system_theme') ?? true;

    ThemeMode themeMode;
    if (savedTheme != null) {
      themeMode = ThemeMode.values.firstWhere(
        (e) => e.toString() == savedTheme,
        orElse: () => ThemeMode.system,
      );
    } else {
      themeMode = ThemeMode.system;
    }

    _currentState = ThemeState(
      themeMode: themeMode,
      followSystem: followSystem,
    );
    _stateController.add(_currentState);
  }

  void _handleSetThemeMode(SetThemeModeEvent event) {
    _currentState = _currentState.copyWith(
      themeMode: event.themeMode,
      followSystem: false,
    );
    _saveTheme();
    _stateController.add(_currentState);
  }

  void _handleToggleTheme() {
    ThemeMode newMode;
    switch (_currentState.themeMode) {
      case ThemeMode.light:
        newMode = ThemeMode.dark;
        break;
      case ThemeMode.dark:
        newMode = ThemeMode.light;
        break;
      case ThemeMode.system:
        // Check current system brightness
        final brightness = SchedulerBinding.instance.window.platformBrightness;
        newMode = brightness == Brightness.light
            ? ThemeMode.dark
            : ThemeMode.light;
        break;
    }

    _currentState = _currentState.copyWith(
      themeMode: newMode,
      followSystem: false,
    );
    _saveTheme();
    _stateController.add(_currentState);
  }

  void _handleSetFollowSystem(SetFollowSystemEvent event) {
    _currentState = _currentState.copyWith(
      followSystem: event.followSystem,
      themeMode: event.followSystem
          ? ThemeMode.system
          : _currentState.themeMode,
    );
    _saveTheme();
    _stateController.add(_currentState);
  }

  void _handleSystemThemeChanged(SystemThemeChangedEvent event) {
    if (_currentState.followSystem) {
      // When following system, update to reflect system change
      _stateController.add(_currentState);
    }
  }

  void _saveTheme() {
    _storage.saveThemeMode(_currentState.themeMode.toString());
    _storage.setBool('follow_system_theme', _currentState.followSystem);
  }

  // Public methods for UI
  void setLightMode() => add(SetThemeModeEvent(ThemeMode.light));
  void setDarkMode() => add(SetThemeModeEvent(ThemeMode.dark));
  void setSystemMode() => add(SetFollowSystemEvent(true));
  void toggleTheme() => add(ToggleThemeEvent());

  Brightness getEffectiveBrightness(BuildContext context) {
    if (_currentState.themeMode == ThemeMode.system) {
      return MediaQuery.platformBrightnessOf(context);
    }
    return _currentState.themeMode == ThemeMode.dark
        ? Brightness.dark
        : Brightness.light;
  }

  bool isDarkMode(BuildContext context) {
    return getEffectiveBrightness(context) == Brightness.dark;
  }

  void dispose() {
    _stateController.close();
    _eventController.close();
  }
}

// Singleton instance
final themeBloc = ThemeBloc();

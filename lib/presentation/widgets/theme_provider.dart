// lib/presentation/widgets/theme_provider.dart

import 'package:flutter/material.dart';
import '../blocs/theme_bloc.dart';

class ThemeProvider extends InheritedWidget {
  final ThemeBloc bloc;

  const ThemeProvider({super.key, required this.bloc, required super.child});

  static ThemeBloc of(BuildContext context) {
    final provider = context
        .dependOnInheritedWidgetOfExactType<ThemeProvider>();
    assert(provider != null, 'No ThemeProvider found in context');
    return provider!.bloc;
  }

  @override
  bool updateShouldNotify(ThemeProvider oldWidget) => false;
}

class ThemeBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, ThemeState state) builder;

  const ThemeBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    final bloc = ThemeProvider.of(context);

    return StreamBuilder<ThemeState>(
      stream: bloc.stateStream,
      initialData: bloc.currentState,
      builder: (context, snapshot) {
        return builder(context, snapshot.data!);
      },
    );
  }
}

import 'package:ayuntamiento_incidencias/src/core/app_theme.dart';
import 'package:ayuntamiento_incidencias/src/core/theme_controller.dart';
import 'package:ayuntamiento_incidencias/src/features/auth/presentation/auth_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      title: 'Incidencias Cantillana',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: const AuthWidget(),
    );
  }
}
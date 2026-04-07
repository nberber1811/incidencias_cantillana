import 'package:ayuntamiento_incidencias/src/core/app_theme.dart';
import 'package:ayuntamiento_incidencias/src/features/auth/presentation/auth_widget.dart';
import 'package:flutter/material.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ayuntamiento Cantillana',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const AuthWidget(),
    );
  }
}
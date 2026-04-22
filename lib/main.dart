import 'package:ayuntamiento_incidencias/src/features/auth/data/auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ayuntamiento_incidencias/src/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final authRepository = AuthRepository();
  final initialUser = await authRepository.getPersistedUser();

  runApp(
    ProviderScope(
      overrides: [
        authStateProvider.overrideWith((ref) => initialUser),
      ],
      child: const MyApp(),
    ),
  );
}
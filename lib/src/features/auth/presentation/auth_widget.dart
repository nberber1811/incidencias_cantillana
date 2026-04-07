import 'package:ayuntamiento_incidencias/src/features/admin/presentation/admin_home_screen.dart';
import 'package:ayuntamiento_incidencias/src/features/auth/data/auth_repository.dart';
import 'package:ayuntamiento_incidencias/src/features/auth/domain/app_user.dart';
import 'package:ayuntamiento_incidencias/src/features/auth/presentation/auth_controller.dart';
import 'package:ayuntamiento_incidencias/src/features/auth/presentation/login_screen.dart';
import 'package:ayuntamiento_incidencias/src/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthWidget extends ConsumerWidget {
  const AuthWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isGuest = ref.watch(isGuestProvider);
    if (isGuest) return const HomeScreen();

    final user = ref.watch(authStateProvider);

    if (user != null) {
      if (user.role == UserRole.admin) {
        return const AdminHomeScreen();
      }
      return const HomeScreen();
    }

    return const LoginScreen();
  }
}

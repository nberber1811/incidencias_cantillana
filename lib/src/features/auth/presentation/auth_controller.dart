import 'package:ayuntamiento_incidencias/src/features/auth/data/auth_repository.dart';
import 'package:ayuntamiento_incidencias/src/features/auth/domain/app_user.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

final authControllerProvider = StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  return AuthController(
    ref.watch(authRepositoryProvider),
    ref,
  );
});

class AuthController extends StateNotifier<AsyncValue<void>> {
  final AuthRepository _authRepository;
  final Ref _ref;

  // Creamos la instancia fuera para evitar reinicializaciones
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb ? '519426341147-c4qjcm2dk41uoli6reldda6a1m7qj5l8.apps.googleusercontent.com' : null,
    serverClientId: kIsWeb ? null : '519426341147-c4qjcm2dk41uoli6reldda6a1m7qj5l8.apps.googleusercontent.com',
  );

  AuthController(this._authRepository, this._ref) : super(const AsyncData(null));

  Future<void> signIn(String email, String password) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() => _authRepository.login(email, password));
    if (result.hasValue) {
      _ref.read(authStateProvider.notifier).state = result.value;
      state = const AsyncData(null);
    } else {
      state = AsyncError(result.error!, result.stackTrace!);
    }
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncLoading();
    try {
      final googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        state = const AsyncData(null);
        return;
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      if (idToken == null && accessToken == null) {
        throw Exception('No se pudo obtener ningún token de Google');
      }

      final result = await _authRepository.loginWithGoogle(
        idToken: idToken,
        accessToken: accessToken,
      );
      _ref.read(authStateProvider.notifier).state = result;
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<bool> signUp(String email, String password, {String? nombre, String? telefono}) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() => _authRepository.register(email, password, nombre ?? '', telefono ?? ''));
    if (result.hasValue) {
      // Ya no hacemos login automático si queremos, o sí podemos si el backend devuelve el usuario
      state = const AsyncData(null);
      return true;
    } else {
      state = AsyncError(result.error!, result.stackTrace!);
      return false;
    }
  }

  Future<bool> updateProfile({required String nombre, required String telefono}) async {
    final user = _ref.read(authStateProvider);
    if (user == null) return false;

    state = const AsyncLoading();
    final result = await AsyncValue.guard(() => _authRepository.updateProfile(user.uid, nombre, telefono));
    if (result.hasValue && result.value != null) {
      _ref.read(authStateProvider.notifier).state = result.value;
      state = const AsyncData(null);
      return true;
    } else {
      state = AsyncError(result.error ?? 'Failed to update', StackTrace.current);
      return false;
    }
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    _ref.read(authStateProvider.notifier).state = null;
    state = await AsyncValue.guard(() => _authRepository.signOut());
  }
}

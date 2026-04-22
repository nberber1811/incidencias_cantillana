import 'package:ayuntamiento_incidencias/src/features/auth/data/auth_repository.dart';
import 'package:ayuntamiento_incidencias/src/features/auth/domain/app_user.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authControllerProvider = StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  return AuthController(
    ref.watch(authRepositoryProvider),
    ref,
  );
});

class AuthController extends StateNotifier<AsyncValue<void>> {
  final AuthRepository _authRepository;
  final Ref _ref;

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

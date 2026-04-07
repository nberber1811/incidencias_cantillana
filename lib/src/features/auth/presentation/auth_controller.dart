import 'package:ayuntamiento_incidencias/src/features/auth/data/auth_repository.dart';
import 'package:ayuntamiento_incidencias/src/features/auth/domain/app_user.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final isGuestProvider = StateProvider<bool>((ref) => false);

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

  void signInAsGuest() {
    _ref.read(isGuestProvider.notifier).state = true;
  }

  Future<void> signIn(String email, String password) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() => _authRepository.signInWithEmailAndPassword(email, password));
    if (result.hasValue) {
      _ref.read(authStateProvider.notifier).state = result.value;
      state = const AsyncData(null);
    } else {
      state = AsyncError(result.error!, result.stackTrace!);
    }
  }

  Future<void> signUp(String email, String password, {String? nombre}) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() => _authRepository.createUserWithEmailAndPassword(email, password, nombre: nombre));
    if (result.hasValue) {
      _ref.read(authStateProvider.notifier).state = result.value;
      state = const AsyncData(null);
    } else {
      state = AsyncError(result.error!, result.stackTrace!);
    }
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    _ref.read(isGuestProvider.notifier).state = false;
    _ref.read(authStateProvider.notifier).state = null;
    state = await AsyncValue.guard(() => _authRepository.signOut());
  }
}

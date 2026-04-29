import 'package:ayuntamiento_incidencias/src/features/admin/data/admin_repository.dart';
import 'package:ayuntamiento_incidencias/src/features/auth/domain/app_user.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider para la lista de usuarios
final allUsersProvider = FutureProvider.autoDispose<List<AppUser>>((ref) async {
  return ref.watch(adminRepositoryProvider).getAllUsers();
});

// Provider para la lista de técnicos
final techniciansProvider = FutureProvider.autoDispose<List<AppUser>>((ref) async {
  return ref.watch(adminRepositoryProvider).getTechnicians();
});

// Controlador para acciones de administrador
final adminControllerProvider = StateNotifierProvider<AdminController, AsyncValue<void>>((ref) {
  return AdminController(ref.watch(adminRepositoryProvider), ref);
});

class AdminController extends StateNotifier<AsyncValue<void>> {
  final AdminRepository _repository;
  final Ref _ref;

  AdminController(this._repository, this._ref) : super(const AsyncData(null));

  Future<void> changeUserRole(String uid, int newRolId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repository.updateUserRole(uid, newRolId));
    if (state.hasError) throw state.error!;
    // Refrescamos la lista de usuarios tras el cambio
    _ref.invalidate(allUsersProvider);
  }

  Future<void> assignTechnician(int incidenciaId, String tecnicoId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repository.assignIncidencia(incidenciaId, tecnicoId));
    if (state.hasError) throw state.error!;
    // Nota: Aquí se podría invalidar el stream de incidencias si es necesario
  }

  Future<void> deleteFinalIncidencias({int? estadoId}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repository.deleteFinalIncidencias(estadoId: estadoId));
    if (state.hasError) throw state.error!;
  }

  Future<void> createCategory(String nombre, {String? descripcion}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repository.addCategory(nombre, descripcion: descripcion));
    if (state.hasError) throw state.error!;
  }

  Future<void> createRole(String nombre, {String? descripcion}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repository.addRole(nombre, descripcion: descripcion));
    if (state.hasError) throw state.error!;
  }

  Future<void> updateCategory(int id, String nombre, {String? descripcion}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repository.updateCategory(id, nombre, descripcion: descripcion));
    if (state.hasError) throw state.error!;
  }

  Future<void> deleteCategory(int id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repository.deleteCategory(id));
    if (state.hasError) throw state.error!;
  }

  Future<void> updateRole(int id, String nombre, {String? descripcion}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repository.updateRole(id, nombre, descripcion: descripcion));
    if (state.hasError) throw state.error!;
  }

  Future<void> deleteRole(int id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repository.deleteRole(id));
    if (state.hasError) throw state.error!;
  }
}

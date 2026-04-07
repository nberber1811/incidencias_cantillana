import 'dart:io';
import 'package:ayuntamiento_incidencias/src/features/auth/data/auth_repository.dart';
import 'package:ayuntamiento_incidencias/src/features/auth/presentation/auth_controller.dart';
import 'package:ayuntamiento_incidencias/src/features/incidencias/data/incidencia_repository.dart';
import 'package:ayuntamiento_incidencias/src/features/incidencias/domain/incidencia.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

final incidenciaControllerProvider = StateNotifierProvider<IncidenciaController, AsyncValue<void>>((ref) {
  return IncidenciaController(
    ref.watch(incidenciaRepositoryProvider),
    ref,
  );
});

class IncidenciaController extends StateNotifier<AsyncValue<void>> {
  final IncidenciaRepository _repository;
  final Ref _ref;

  IncidenciaController(this._repository, this._ref) : super(const AsyncData(null));

  Future<bool> submitIncidencia({
    required String title,
    required String description,
    required String category,
    File? image,
    double? latitude,
    double? longitude,
  }) async {
    final isGuest = _ref.read(isGuestProvider);
    final user = _ref.read(authStateProvider);

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      if (isGuest) {
        await Future.delayed(const Duration(seconds: 2));
        return;
      }
      
      String? imageUrl;
      if (image != null) {
        imageUrl = await _repository.uploadImage(image);
      }

      final incidencia = Incidencia(
        id: const Uuid().v4(),
        userId: user?.uid ?? '',
        title: title,
        description: description,
        category: category,
        imageUrl: imageUrl,
        latitude: latitude,
        longitude: longitude,
        createdAt: DateTime.now(),
      );

      await _repository.createIncidencia(incidencia);
    });
    return !state.hasError;
  }
}

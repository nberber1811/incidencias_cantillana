import 'dart:io';
import 'package:ayuntamiento_incidencias/src/features/auth/data/auth_repository.dart';
import 'package:ayuntamiento_incidencias/src/features/auth/presentation/auth_controller.dart';
import 'package:ayuntamiento_incidencias/src/features/incidencias/data/incidencia_repository.dart';
import 'package:ayuntamiento_incidencias/src/features/incidencias/domain/incidencia.dart';
import 'package:image_picker/image_picker.dart';
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
    required String titulo,
    required String descripcion,
    required String categoria,
    XFile? imagen,
    double? latitud,
    double? longitud,
    String? direccion,
  }) async {
    final user = _ref.read(authStateProvider);

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      
      String? imageUrl;
      if (imagen != null) {
        imageUrl = await _repository.uploadImage(imagen);
      }

      // Mapeo simple de categorías a IDs (debe coincidir con init-db.js)
      int? categoryId;
      if (categoria.contains('Alumbrado')) categoryId = 1;
      else if (categoria.contains('Limpieza')) categoryId = 2;
      else if (categoria.contains('Vía')) categoryId = 3;
      else if (categoria.contains('Parques')) categoryId = 4;

      final incidencia = Incidencia(
        id: const Uuid().v4(),
        usuarioId: user?.uid ?? '',
        titulo: titulo,
        descripcion: descripcion,
        categoriaId: categoryId,
        image: imageUrl,
        latitud: latitud,
        longitud: longitud,
        direccion: direccion,
        fechaCreacion: DateTime.now(),
      );

      await _repository.createIncidencia(incidencia);
    });
    return !state.hasError;
  }

  Future<bool> editIncidencia({
    required String id,
    required String titulo,
    required String descripcion,
    required String categoria,
    XFile? imagen,
    String? existingImageUrl,
    double? latitud,
    double? longitud,
    String? direccion,
  }) async {
    final user = _ref.read(authStateProvider);

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      String? imageUrl = existingImageUrl;
      if (imagen != null) {
        imageUrl = await _repository.uploadImage(imagen);
      }

      int? categoryId;
      if (categoria.contains('Alumbrado')) categoryId = 1;
      else if (categoria.contains('Limpieza')) categoryId = 2;
      else if (categoria.contains('Vía')) categoryId = 3;
      else if (categoria.contains('Parques')) categoryId = 4;

      final incidencia = Incidencia(
        id: id,
        usuarioId: user?.uid ?? '',
        titulo: titulo,
        descripcion: descripcion,
        categoriaId: categoryId,
        image: imageUrl,
        latitud: latitud,
        longitud: longitud,
        direccion: direccion,
        fechaCreacion: DateTime.now(), // El backend mantendrá la fecha original o podemos manejarlo
      );

      await _repository.updateIncidencia(incidencia);
    });
    return !state.hasError;
  }

  Future<bool> deleteIncidencia(String id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repository.deleteIncidencia(id));
    return !state.hasError;
  }
}

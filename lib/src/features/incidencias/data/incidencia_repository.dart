import 'dart:convert';
import 'dart:io';
import 'package:ayuntamiento_incidencias/src/features/incidencias/domain/incidencia.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

final incidenciaRepositoryProvider = Provider<IncidenciaRepository>((ref) {
  return IncidenciaRepository();
});

final userIncidenciasStreamProvider = StreamProvider.family<List<Incidencia>, String>((ref, userId) {
  return ref.watch(incidenciaRepositoryProvider).watchUserIncidencias(userId);
});

final allIncidenciasStreamProvider = StreamProvider<List<Incidencia>>((ref) {
  return ref.watch(incidenciaRepositoryProvider).watchAllIncidencias();
});

class IncidenciaRepository {
  // Base URL of the new API
  // Base URL of the new Node.js API
  final String baseUrl = 'https://alumno23.fpcantillana.org/api/incidencias';

  IncidenciaRepository();

  Stream<List<Incidencia>> watchUserIncidencias(String userId) async* {
    while (true) {
      try {
        final response = await http.get(Uri.parse('$baseUrl/user/$userId'));
        if (response.statusCode == 200) {
          final List<dynamic> data = json.decode(response.body);
          yield data.map((item) => Incidencia.fromJson(item)).toList();
        } else {
          // Si el servidor falla, devolvemos lista vacía para quitar el spinner
          yield [];
        }
      } catch (e) {
        // Fallback en caso de error
        yield [];
      }
      await Future.delayed(const Duration(seconds: 5));
    }
  }

  Stream<List<Incidencia>> watchAllIncidencias() async* {
    while (true) {
      try {
        debugPrint("DEBUG: Cargando todas las incidencias...");
        final response = await http.get(Uri.parse(baseUrl));
        if (response.statusCode == 200) {
          final List<dynamic> data = json.decode(response.body);
          debugPrint("DEBUG: Incidencias recibidas: ${data.length}");
          yield data.map((item) => Incidencia.fromJson(item)).toList();
        } else {
          debugPrint("DEBUG: Error servidor: ${response.statusCode}");
          yield [];
        }
      } catch (e) {
        debugPrint("DEBUG: Excepción en watchAllIncidencias: $e");
        yield [];
      }
      await Future.delayed(const Duration(seconds: 10));
    }
  }

  Future<String> uploadImage(XFile file) async {
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload'));
    
    if (kIsWeb) {
      final bytes = await file.readAsBytes();
      request.files.add(http.MultipartFile.fromBytes(
        'image',
        bytes,
        filename: file.name,
      ));
    } else {
      request.files.add(await http.MultipartFile.fromPath('image', file.path));
    }
    
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['url']; // Devolver el nombre del archivo
    } else {
      throw Exception('Failed to upload image');
    }
  }

  Future<void> createIncidencia(Incidencia incidencia) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(incidencia.toJson()),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Failed to create incidencia');
    }
  }

  Future<void> updateIncidencia(Incidencia incidencia) async {
    final response = await http.put(
      Uri.parse('$baseUrl/${incidencia.id}'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(incidencia.toJson()),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to update incidencia');
    }
  }

  Future<void> deleteIncidencia(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/$id'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete incidencia');
    }
  }

  Future<void> updateIncidenciaStatus(String id, int estadoId, String usuarioId) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/$id/status'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'estado_id': estadoId,
        'usuario_id': usuarioId,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to update status');
    }
  }
}

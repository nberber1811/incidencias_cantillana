import 'dart:convert';
import 'dart:io';
import 'package:ayuntamiento_incidencias/src/features/incidencias/domain/incidencia.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

final incidenciaRepositoryProvider = Provider<IncidenciaRepository>((ref) {
  return IncidenciaRepository();
});

final userIncidenciasStreamProvider = StreamProvider.family<List<Incidencia>, String>((ref, userId) {
  return ref.watch(incidenciaRepositoryProvider).watchUserIncidencias(userId);
});

class IncidenciaRepository {
  // Base URL of the new API
  final String baseUrl = 'http://alumno23.fpcantillana.org/api';

  IncidenciaRepository();

  Stream<List<Incidencia>> watchUserIncidencias(String userId) async* {
    while (true) {
      try {
        final response = await http.get(Uri.parse('$baseUrl/get_incidencias.php?userId=$userId'));
        if (response.statusCode == 200) {
          final List<dynamic> data = json.decode(response.body);
          yield data.map((item) => Incidencia.fromJson(item)).toList();
        }
      } catch (e) {
        // Fallback to mock data on error for better UX
        yield [
          Incidencia(
            id: '1',
            userId: 'guest',
            title: 'Ejemplo: Farola rota',
            description: 'Conectando con el nuevo servidor...',
            category: 'Alumbrado',
            status: IncidenciaStatus.pending,
            createdAt: DateTime.now(),
          ),
        ];
      }
      await Future.delayed(const Duration(seconds: 5)); // Polling for simulate stream
    }
  }

  Stream<List<Incidencia>> watchAllIncidencias() async* {
    while (true) {
      try {
        final response = await http.get(Uri.parse('$baseUrl/get_incidencias.php'));
        if (response.statusCode == 200) {
          final List<dynamic> data = json.decode(response.body);
          yield data.map((item) => Incidencia.fromJson(item)).toList();
        }
      } catch (e) {
        yield [];
      }
      await Future.delayed(const Duration(seconds: 10));
    }
  }

  Future<String> uploadImage(File file) async {
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload.php'));
    request.files.add(await http.MultipartFile.fromPath('image', file.path));
    
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['url']; // The PHP script should return the image URL
    } else {
      throw Exception('Failed to upload image');
    }
  }

  Future<void> createIncidencia(Incidencia incidencia) async {
    final response = await http.post(
      Uri.parse('$baseUrl/save_incidencia.php'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(incidencia.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to create incidencia');
    }
  }

  Future<void> updateIncidenciaStatus(String id, IncidenciaStatus status) async {
    final response = await http.post(
      Uri.parse('$baseUrl/update_status.php'),
      body: {
        'id': id,
        'status': status.name,
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update status');
    }
  }
}

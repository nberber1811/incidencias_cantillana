import 'dart:convert';
import 'package:ayuntamiento_incidencias/src/features/auth/domain/app_user.dart';
import 'package:ayuntamiento_incidencias/src/features/incidencias/domain/incidencia.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

final adminRepositoryProvider = Provider((ref) => AdminRepository());

class AdminRepository {
  final String baseUrl = 'https://alumno23.fpcantillana.org/api/admin';

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<Map<String, String>> _headers() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Obtener todos los usuarios
  Future<List<AppUser>> getAllUsers() async {
    final response = await http.get(Uri.parse('$baseUrl/users'), headers: await _headers());
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((u) => AppUser.fromJson(u)).toList();
    } else {
      throw Exception('Error al obtener usuarios: ${response.body}');
    }
  }

  // Cambiar rol de usuario
  Future<void> updateUserRole(String uid, int rolId) async {
    final response = await http.put(
      Uri.parse('$baseUrl/users/$uid/role'),
      headers: await _headers(),
      body: json.encode({'rol_id': rolId}),
    );
    if (response.statusCode != 200) {
      throw Exception('Error al actualizar rol: ${response.body}');
    }
  }

  // Obtener técnicos
  Future<List<AppUser>> getTechnicians() async {
    final response = await http.get(Uri.parse('$baseUrl/technicians'), headers: await _headers());
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((u) => AppUser.fromJson(u)).toList();
    } else {
      throw Exception('Error al obtener técnicos');
    }
  }

  // Asignar incidencia
  Future<void> assignIncidencia(int id, String tecnicoId) async {
    final response = await http.put(
      Uri.parse('$baseUrl/incidencias/$id/assign'),
      headers: await _headers(),
      body: json.encode({'tecnicoId': tecnicoId}),
    );
    if (response.statusCode != 200) {
      throw Exception('Error al asignar incidencia: ${response.body}');
    }
  }

  Future<void> deleteFinalIncidencias({int? estadoId}) async {
    String url = '$baseUrl/incidencias/finalizadas';
    if (estadoId != null) {
      url += '?estadoId=$estadoId';
    }
    
    final response = await http.delete(
      Uri.parse(url),
      headers: await _headers(),
    );
    if (response.statusCode != 200) {
      throw Exception('Error al limpiar historial: ${response.body}');
    }
  }

  // Crear categoría
  Future<void> addCategory(String nombre, {String? descripcion}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/categories'),
      headers: await _headers(),
      body: json.encode({'nombre': nombre, 'descripcion': descripcion}),
    );
    if (response.statusCode != 201) {
      throw Exception('Error al crear categoría: ${response.body}');
    }
  }

  // Crear rol (estado)
  Future<void> addRole(String nombre, {String? descripcion}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/roles'),
      headers: await _headers(),
      body: json.encode({'nombre': nombre, 'descripcion': descripcion}),
    );
    if (response.statusCode != 201) {
      throw Exception('Error al crear rol/estado: ${response.body}');
    }
  }

  // Actualizar categoría
  Future<void> updateCategory(int id, String nombre, {String? descripcion}) async {
    final response = await http.put(
      Uri.parse('$baseUrl/categories/$id'),
      headers: await _headers(),
      body: json.encode({'nombre': nombre, 'descripcion': descripcion}),
    );
    if (response.statusCode != 200) {
      throw Exception('Error al actualizar categoría: ${response.body}');
    }
  }

  // Borrar categoría
  Future<void> deleteCategory(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/categories/$id'),
      headers: await _headers(),
    );
    if (response.statusCode != 200) {
      String detail = 'Error al eliminar categoría';
      try {
        final error = json.decode(response.body);
        detail = error['message'] ?? detail;
      } catch (e) {
        detail = 'Error del servidor (HTML): ${response.statusCode}';
      }
      throw Exception(detail);
    }
  }

  // Actualizar rol/estado
  Future<void> updateRole(int id, String nombre, {String? descripcion}) async {
    final response = await http.put(
      Uri.parse('$baseUrl/roles/$id'),
      headers: await _headers(),
      body: json.encode({'nombre': nombre, 'descripcion': descripcion}),
    );
    if (response.statusCode != 200) {
      throw Exception('Error al actualizar rol/estado: ${response.body}');
    }
  }

  // Borrar rol/estado
  Future<void> deleteRole(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/roles/$id'),
      headers: await _headers(),
    );
    if (response.statusCode != 200) {
      String detail = 'Error al eliminar rol/estado';
      try {
        final error = json.decode(response.body);
        detail = error['message'] ?? detail;
      } catch (e) {
        detail = 'Error del servidor (HTML): ${response.statusCode}';
      }
      throw Exception(detail);
    }
  }
}

import 'dart:async';
import 'dart:convert';
import 'package:ayuntamiento_incidencias/src/features/auth/domain/app_user.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final authStateProvider = StateProvider<AppUser?>((ref) => null);

class AuthRepository {
  final String baseUrl = 'https://alumno23.fpcantillana.org/api/auth';

  AuthRepository();

  static const _userKey = 'auth_user';
  static const _tokenKey = 'auth_token';

  Future<AppUser?> register(String email, String password, String nombre, String telefono) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'password': password,
        'nombre': nombre,
        'telefono': telefono,
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = json.decode(response.body);
      final user = AppUser.fromJson(data['user']);
      await persistUser(user);
      return user;
    } else {
      final data = json.decode(response.body);
      final detail = data['error_detalle'] ?? data['message'] ?? 'Error desconocido';
      throw Exception(detail);
    }
  }

  Future<AppUser?> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final user = AppUser.fromJson(data['user']);
      final token = data['token'];
      
      final prefs = await SharedPreferences.getInstance();
      if (token != null) await prefs.setString(_tokenKey, token);
      
      await persistUser(user);
      return user;
    } else {
      final data = json.decode(response.body);
      throw Exception(data['message'] ?? 'Error al iniciar sesión');
    }
  }

  Future<AppUser?> updateProfile(String uid, String nombre, String telefono) async {
    final response = await http.put(
      Uri.parse('$baseUrl/profile/$uid'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'nombre': nombre,
        'telefono': telefono,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body);
      final user = AppUser.fromJson(data['user']);
      await persistUser(user);
      return user;
    } else {
      throw Exception('Failed to update profile');
    }
  }

  Future<void> persistUser(AppUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, json.encode(user.toJson()));
  }

  Future<AppUser?> getPersistedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    if (userJson != null) {
      return AppUser.fromJson(json.decode(userJson));
    }
    return null;
  }

  Future<void> clearPersistedUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.remove(_tokenKey);
  }

  Future<void> signOut() async {
    await clearPersistedUser();
  }
}

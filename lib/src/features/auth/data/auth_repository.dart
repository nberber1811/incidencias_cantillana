import 'dart:async';
import 'dart:convert';
import 'package:ayuntamiento_incidencias/src/features/auth/domain/app_user.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final authStateProvider = StateProvider<AppUser?>((ref) => null);

class AuthRepository {
  final String baseUrl = 'https://alumno23.fpcantillana.org/api/auth';

  AuthRepository();

  Future<AppUser?> signInWithEmailAndPassword(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body);
      return AppUser.fromJson(data['user']);
    } else {
      throw Exception('Login failed');
    }
  }

  Future<AppUser?> createUserWithEmailAndPassword(String email, String password, {String? nombre, String? telefono}) async {
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

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body);
      return AppUser.fromJson(data['user']);
    } else {
      throw Exception('Registration failed');
    }
  }

  Future<void> signOut() async {
    // Session is handled in Flutter for now (local memory)
  }
}

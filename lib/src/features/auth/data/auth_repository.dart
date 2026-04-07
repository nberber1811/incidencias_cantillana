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
  final String baseUrl = 'https://alumno23.fpcantillana.org/api';

  AuthRepository();

  Future<AppUser?> signInWithEmailAndPassword(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login.php'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return AppUser.fromJson(data['user']);
    } else {
      throw Exception('Login failed');
    }
  }

  Future<AppUser?> createUserWithEmailAndPassword(String email, String password, {String? nombre}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register.php'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'password': password, 'nombre': nombre}),
    );

    if (response.statusCode == 200) {
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

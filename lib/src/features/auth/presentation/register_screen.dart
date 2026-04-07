import 'package:ayuntamiento_incidencias/src/features/auth/presentation/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<void>>(
      authControllerProvider,
      (previous, next) {
        next.whenOrNull(
          error: (e, st) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: $e')),
            );
          },
        );
      },
    );

    final state = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Crear Cuenta')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                Text(
                  'Únete a nosotros',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                TextFormField(
                  controller: _nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre Completo',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) =>
                      (value == null || value.isEmpty) ? 'Por favor introduce tu nombre' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) =>
                      (value == null || !value.contains('@')) ? 'Email inválido' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  obscureText: true,
                  validator: (value) =>
                      (value != null && value.length < 6) ? 'Mínimo 6 caracteres' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'Confirmar Contraseña',
                    prefixIcon: Icon(Icons.lock_reset_outlined),
                  ),
                  obscureText: true,
                  validator: (value) =>
                      value != _passwordController.text ? 'No coincide' : null,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: state.isLoading
                      ? null
                      : () {
                          if (_formKey.currentState!.validate()) {
                            ref.read(authControllerProvider.notifier).signUp(
                                  _emailController.text,
                                  _passwordController.text,
                                  nombre: _nombreController.text,
                                );
                            // Note: AuthWidget will handle the redirection once signed up
                            Navigator.pop(context);
                          }
                        },
                  child: state.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Registrarse'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

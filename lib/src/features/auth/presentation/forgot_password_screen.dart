import 'package:ayuntamiento_incidencias/src/features/auth/presentation/auth_controller.dart';
import 'package:ayuntamiento_incidencias/src/features/auth/presentation/auth_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _tokenController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _emailSent = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Recuperar Contraseña')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 450),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!_emailSent) ...[
                    const Text(
                      'Introduce tu email para recibir un código de recuperación.',
                      style: TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
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
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: state.isLoading
                          ? null
                          : () async {
                              if (_formKey.currentState!.validate()) {
                                final success = await ref
                                    .read(authControllerProvider.notifier)
                                    .forgotPassword(_emailController.text);
                                if (success) {
                                  setState(() => _emailSent = true);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Email enviado. Revisa tu bandeja de entrada.')),
                                  );
                                }
                              }
                            },
                      child: state.isLoading
                          ? const CircularProgressIndicator()
                          : const Text('Enviar Email'),
                    ),
                  ] else ...[
                    const Text(
                      'Introduce el código que has recibido y tu nueva contraseña.',
                      style: TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _tokenController,
                      decoration: const InputDecoration(
                        labelText: 'Código de recuperación',
                        prefixIcon: Icon(Icons.key),
                      ),
                      validator: (value) => (value == null || value.isEmpty) ? 'Campo obligatorio' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _newPasswordController,
                      decoration: const InputDecoration(
                        labelText: 'Nueva Contraseña',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      obscureText: true,
                      validator: (value) =>
                          (value != null && value.length < 6) ? 'Mínimo 6 caracteres' : null,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: state.isLoading
                          ? null
                          : () async {
                              if (_formKey.currentState!.validate()) {
                                final success = await ref
                                    .read(authControllerProvider.notifier)
                                    .resetPassword(
                                      _tokenController.text,
                                      _newPasswordController.text,
                                    );
                                if (success) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Contraseña actualizada con éxito')),
                                  );
                                  Navigator.pop(context);
                                }
                              }
                            },
                      child: state.isLoading
                          ? const CircularProgressIndicator()
                          : const Text('Cambiar Contraseña'),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _emailSent = false),
                      child: const Text('¿No has recibido el código? Reintentar'),
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => const AuthWidget()),
                        (route) => false,
                      );
                    },
                    child: const Text('Volver al Login'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

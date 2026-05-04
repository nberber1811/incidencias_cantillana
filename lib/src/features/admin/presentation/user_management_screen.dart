import 'package:ayuntamiento_incidencias/src/features/admin/presentation/admin_controller.dart';
import 'package:ayuntamiento_incidencias/src/features/auth/domain/app_user.dart';
import 'package:ayuntamiento_incidencias/src/features/auth/presentation/auth_controller.dart';
import 'package:ayuntamiento_incidencias/src/features/auth/presentation/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UserManagementScreen extends ConsumerStatefulWidget {
  const UserManagementScreen({super.key});

  @override
  ConsumerState<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen> {
  bool _isSearching = false;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(allUsersProvider);

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Buscar usuarios...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.white70),
                ),
                style: const TextStyle(color: Colors.white),
                onChanged: (value) => setState(() => _searchQuery = value),
              )
            : const Text('Gestión de Usuarios'),
        actions: [
          if (!_isSearching)
            IconButton(
              onPressed: () => setState(() => _isSearching = true),
              icon: const Icon(Icons.search),
            ),
          if (_isSearching && _searchQuery.isNotEmpty)
            IconButton(
              onPressed: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
              icon: const Icon(Icons.clear),
            ),
          IconButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen())),
            icon: const Icon(Icons.account_circle_outlined),
          ),
          IconButton(
            onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
        leading: _isSearching
            ? IconButton(
                onPressed: () {
                  setState(() {
                    _isSearching = false;
                    _searchQuery = '';
                    _searchController.clear();
                  });
                },
                icon: const Icon(Icons.arrow_back),
              )
            : null,
      ),
      body: usersAsync.when(
        data: (users) {
          var filteredUsers = users;
          if (_searchQuery.isNotEmpty) {
            final query = _searchQuery.toLowerCase();
            filteredUsers = users.where((u) => 
              (u.nombre?.toLowerCase().contains(query) ?? false) || 
              u.email.toLowerCase().contains(query)
            ).toList();
          }

          return Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 800),
              child: filteredUsers.isEmpty 
                ? const Center(child: Text('No se encontraron usuarios'))
                : ListView.separated(
                    itemCount: filteredUsers.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final user = filteredUsers[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getRoleColor(user.rolId),
                          child: const Icon(Icons.person, color: Colors.white),
                        ),
                        title: Text(user.nombre ?? 'Sin nombre', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${user.email}\nRol: ${_getRoleName(user.rolId)}'),
                        isThreeLine: true,
                        trailing: PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert),
                          onSelected: (action) async {
                            if (action == 'delete') {
                              final confirmed = await _showConfirmationDialog(
                                context,
                                '¿Eliminar usuario?',
                                'Esta acción no se puede deshacer. El usuario será borrado permanentemente.',
                                Colors.red,
                              );
                              if (confirmed) {
                                try {
                                  await ref.read(adminControllerProvider.notifier).deleteUser(user.uid);
                                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Usuario eliminado')));
                                } catch (e) {
                                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                                }
                              }
                            } else if (action == 'block') {
                              final isBlocking = !user.bloqueado;
                              final confirmed = await _showConfirmationDialog(
                                context,
                                isBlocking ? '¿Bloquear usuario?' : '¿Desbloquear usuario?',
                                isBlocking 
                                  ? 'El usuario no podrá iniciar sesión en la aplicación.' 
                                  : 'El usuario volverá a tener acceso a la aplicación.',
                                isBlocking ? Colors.orange : Colors.green,
                              );
                              if (confirmed) {
                                try {
                                  await ref.read(adminControllerProvider.notifier).toggleBlockUser(user.uid, isBlocking);
                                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isBlocking ? 'Usuario bloqueado' : 'Usuario desbloqueado')));
                                } catch (e) {
                                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                                }
                              }
                            } else {
                              // Cambiar rol
                              final newRole = int.parse(action);
                              ref.read(adminControllerProvider.notifier).changeUserRole(user.uid, newRole);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(value: '1', child: Text('Hacer Ciudadano')),
                            const PopupMenuItem(value: '2', child: Text('Hacer Técnico')),
                            const PopupMenuItem(value: '3', child: Text('Hacer Administrador')),
                            const PopupMenuDivider(),
                            PopupMenuItem(
                              value: 'block', 
                              child: Text(user.bloqueado ? 'Desbloquear Cuenta' : 'Bloquear Cuenta', style: TextStyle(color: user.bloqueado ? Colors.green : Colors.orange)),
                            ),
                            const PopupMenuItem(
                              value: 'delete', 
                              child: Text('Eliminar Cuenta', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }

  String _getRoleName(int id) {
    switch (id) {
      case 1: return 'Ciudadano';
      case 2: return 'Técnico';
      case 3: return 'Administrador';
      default: return 'Desconocido';
    }
  }

  Color _getRoleColor(int id) {
    switch (id) {
      case 1: return Colors.blue;
      case 2: return Colors.orange;
      case 3: return Colors.red;
      default: return Colors.grey;
    }
  }

  Future<bool> _showConfirmationDialog(BuildContext context, String title, String content, Color actionColor) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCELAR'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: actionColor, foregroundColor: Colors.white),
            child: const Text('CONFIRMAR'),
          ),
        ],
      ),
    ) ?? false;
  }
}

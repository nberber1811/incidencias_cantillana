import 'package:ayuntamiento_incidencias/src/features/admin/presentation/admin_incidencia_detail_screen.dart';
import 'package:ayuntamiento_incidencias/src/features/auth/presentation/auth_controller.dart';
import 'package:ayuntamiento_incidencias/src/features/incidencias/data/incidencia_repository.dart';
import 'package:ayuntamiento_incidencias/src/features/incidencias/presentation/map_view_screen.dart';
import 'package:ayuntamiento_incidencias/src/shared/widgets/incidencia_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminHomeScreen extends ConsumerWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allIncidenciasAsync = ref.watch(StreamProvider((ref) => ref.watch(incidenciaRepositoryProvider).watchAllIncidencias()));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Gestión'),
        leading: IconButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MapViewScreen()),
          ),
          icon: const Icon(Icons.map_outlined),
          tooltip: 'Mapa global',
        ),
        actions: [
          IconButton(
            onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: allIncidenciasAsync.when(
        data: (incidencias) {
          if (incidencias.isEmpty) {
            return const Center(child: Text('No hay incidencias para gestionar'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: incidencias.length,
            itemBuilder: (context, index) {
              final incidencia = incidencias[index];
              return IncidenciaCard(
                incidencia: incidencia,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AdminIncidenciaDetailScreen(incidencia: incidencia),
                    ),
                  );
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

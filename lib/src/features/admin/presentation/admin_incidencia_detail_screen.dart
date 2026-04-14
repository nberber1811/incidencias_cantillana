import 'package:ayuntamiento_incidencias/src/features/incidencias/data/incidencia_repository.dart';
import 'package:ayuntamiento_incidencias/src/features/incidencias/domain/incidencia.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ayuntamiento_incidencias/src/features/incidencias/presentation/widgets/html_map_widget.dart';
import 'package:ayuntamiento_incidencias/src/features/auth/data/auth_repository.dart';
import 'package:ayuntamiento_incidencias/src/features/auth/presentation/auth_controller.dart';
import 'package:intl/intl.dart';

class AdminIncidenciaDetailScreen extends ConsumerStatefulWidget {
  final Incidencia incidencia;

  const AdminIncidenciaDetailScreen({super.key, required this.incidencia});

  @override
  ConsumerState<AdminIncidenciaDetailScreen> createState() => _AdminIncidenciaDetailScreenState();
}

class _AdminIncidenciaDetailScreenState extends ConsumerState<AdminIncidenciaDetailScreen> {
  @override
  Widget build(BuildContext context) {
    const String baseUploadUrl = 'https://alumno23.fpcantillana.org/uploads/';

    return Scaffold(
      appBar: AppBar(title: const Text('Detalles de Incidencia')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.incidencia.image != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.network(
                  '$baseUploadUrl${widget.incidencia.image}',
                  width: double.infinity,
                  height: 250,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 24),
            
            if (widget.incidencia.latitud != null && widget.incidencia.longitud != null)
              Container(
                height: 200,
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: HtmlMapWidget(
                    lat: widget.incidencia.latitud!,
                    lng: widget.incidencia.longitud!,
                    incidencias: [widget.incidencia],
                  ),
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.incidencia.categoriaNombre ?? 'Sin categoría',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  DateFormat('dd/MM/yyyy HH:mm').format(widget.incidencia.fechaCreacion),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              widget.incidencia.titulo,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              widget.incidencia.descripcion,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 24),
            Text(
              "Cambiar Estado",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StatusButton(
                  statusId: 1,
                  currentStatusId: widget.incidencia.estadoId,
                  label: 'Abierta',
                  color: Colors.orange,
                  onPressed: () => _updateStatus(ref, context, 1),
                ),
                _StatusButton(
                  statusId: 2,
                  currentStatusId: widget.incidencia.estadoId,
                  label: 'En Proceso',
                  color: Colors.blue,
                  onPressed: () => _updateStatus(ref, context, 2),
                ),
                _StatusButton(
                  statusId: 3,
                  currentStatusId: widget.incidencia.estadoId,
                  label: 'Resuelta',
                  color: Colors.green,
                  onPressed: () => _updateStatus(ref, context, 3),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateStatus(WidgetRef ref, BuildContext context, int estadoId) async {
    final currentUser = ref.read(authStateProvider);
    if (currentUser == null) return;

    try {
      await ref.read(incidenciaRepositoryProvider).updateIncidenciaStatus(
        widget.incidencia.id, 
        estadoId,
        currentUser.uid,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Estado actualizado correctamente')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}

class _StatusButton extends StatelessWidget {
  final int statusId;
  final int currentStatusId;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _StatusButton({
    required this.statusId,
    required this.currentStatusId,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = statusId == currentStatusId;
    return ElevatedButton(
      onPressed: isSelected ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? color.withOpacity(0.2) : color,
        foregroundColor: isSelected ? color : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: isSelected ? 0 : 2,
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}

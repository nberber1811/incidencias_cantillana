import 'package:ayuntamiento_incidencias/src/features/incidencias/data/incidencia_repository.dart';
import 'package:ayuntamiento_incidencias/src/features/incidencias/domain/incidencia.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ayuntamiento_incidencias/src/features/incidencias/presentation/widgets/html_map_widget.dart';
import 'package:ayuntamiento_incidencias/src/features/auth/data/auth_repository.dart';

class TechnicianIncidenciaDetailScreen extends ConsumerStatefulWidget {
  final Incidencia incidencia;
  const TechnicianIncidenciaDetailScreen({super.key, required this.incidencia});

  @override
  ConsumerState<TechnicianIncidenciaDetailScreen> createState() => _TechnicianIncidenciaDetailScreenState();
}

class _TechnicianIncidenciaDetailScreenState extends ConsumerState<TechnicianIncidenciaDetailScreen> {
  final _comentarioController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _comentarioController.text = widget.incidencia.comentarioTecnico ?? '';
  }

  @override
  void dispose() {
    _comentarioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const String baseUploadUrl = 'https://alumno23.fpcantillana.org/uploads/';

    return Scaffold(
      appBar: AppBar(title: const Text('Ejecución de Tarea')),
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
              )
            else if (widget.incidencia.direccion != null && widget.incidencia.direccion!.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.redAccent),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.incidencia.direccion!,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),

            Text(
              widget.incidencia.titulo,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              widget.incidencia.descripcion,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 24),
            
            Text(
              "Comentario Final (Opcional)",
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _comentarioController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Escribe aquí la respuesta para el ciudadano...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
            
            const SizedBox(height: 24),
            Text(
              "Actualizar Estado",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _StatusButton(
                  statusId: 2,
                  currentStatusId: widget.incidencia.estadoId,
                  label: 'En Proceso',
                  color: Colors.blue,
                  onPressed: () => _updateStatus(2),
                ),
                _StatusButton(
                  statusId: 3,
                  currentStatusId: widget.incidencia.estadoId,
                  label: 'Resuelta',
                  color: Colors.green,
                  onPressed: () => _updateStatus(3),
                ),
                _StatusButton(
                  statusId: 4,
                  currentStatusId: widget.incidencia.estadoId,
                  label: 'No Resuelta',
                  color: Colors.orange[800]!,
                  onPressed: () => _updateStatus(4),
                ),
                _StatusButton(
                  statusId: 5,
                  currentStatusId: widget.incidencia.estadoId,
                  label: 'Error / Inválida',
                  color: Colors.redAccent,
                  onPressed: () => _updateStatus(5),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateStatus(int estadoId) async {
    final currentUser = ref.read(authStateProvider);
    if (currentUser == null) return;

    try {
      await ref.read(incidenciaRepositoryProvider).updateIncidenciaStatus(
        widget.incidencia.id, 
        estadoId,
        currentUser.uid,
        comentario: _comentarioController.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tarea actualizada correctamente')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
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
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}

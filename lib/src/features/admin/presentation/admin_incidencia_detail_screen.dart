import 'package:ayuntamiento_incidencias/src/features/incidencias/data/incidencia_repository.dart';
import 'package:ayuntamiento_incidencias/src/features/incidencias/domain/incidencia.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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
    return Scaffold(
      appBar: AppBar(title: const Text('Detalles de Incidencia')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.incidencia.imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.network(
                  widget.incidencia.imageUrl!,
                  width: double.infinity,
                  height: 250,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 24),
            
            if (widget.incidencia.latitude != null && widget.incidencia.longitude != null)
              Container(
                height: 150,
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(widget.incidencia.latitude!, widget.incidencia.longitude!),
                      zoom: 15,
                    ),
                    markers: {
                      Marker(
                        markerId: const MarkerId('pos'),
                        position: LatLng(widget.incidencia.latitude!, widget.incidencia.longitude!),
                      )
                    },
                    liteModeEnabled: true,
                    zoomControlsEnabled: false,
                    scrollGesturesEnabled: false,
                  ),
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.incidencia.category,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  DateFormat('dd/MM/yyyy HH:mm').format(widget.incidencia.createdAt),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              widget.incidencia.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              widget.incidencia.description,
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
                  status: IncidenciaStatus.pending,
                  currentStatus: widget.incidencia.status,
                  label: 'Pendiente',
                  color: Colors.orange,
                  onPressed: () => _updateStatus(ref, context, IncidenciaStatus.pending),
                ),
                _StatusButton(
                  status: IncidenciaStatus.inProgress,
                  currentStatus: widget.incidencia.status,
                  label: 'En Proceso',
                  color: Colors.blue,
                  onPressed: () => _updateStatus(ref, context, IncidenciaStatus.inProgress),
                ),
                _StatusButton(
                  status: IncidenciaStatus.resolved,
                  currentStatus: widget.incidencia.status,
                  label: 'Resuelta',
                  color: Colors.green,
                  onPressed: () => _updateStatus(ref, context, IncidenciaStatus.resolved),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateStatus(WidgetRef ref, BuildContext context, IncidenciaStatus status) async {
    try {
      await ref.read(incidenciaRepositoryProvider).updateIncidenciaStatus(widget.incidencia.id, status);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Estado actualizado a ${status.name}')),
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
  final IncidenciaStatus status;
  final IncidenciaStatus currentStatus;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _StatusButton({
    required this.status,
    required this.currentStatus,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = status == currentStatus;
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

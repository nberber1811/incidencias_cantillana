import 'package:ayuntamiento_incidencias/src/features/incidencias/data/incidencia_repository.dart';
import 'package:ayuntamiento_incidencias/src/features/incidencias/domain/incidencia.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ayuntamiento_incidencias/src/features/incidencias/presentation/widgets/html_map_widget.dart';
import 'package:ayuntamiento_incidencias/src/features/auth/data/auth_repository.dart';
import 'package:ayuntamiento_incidencias/src/features/auth/presentation/auth_controller.dart';
import 'package:ayuntamiento_incidencias/src/features/admin/presentation/admin_controller.dart';
import 'package:intl/intl.dart';

class AdminIncidenciaDetailScreen extends ConsumerStatefulWidget {
  final Incidencia incidencia;

  const AdminIncidenciaDetailScreen({super.key, required this.incidencia});

  @override
  ConsumerState<AdminIncidenciaDetailScreen> createState() => _AdminIncidenciaDetailScreenState();
}

class _AdminIncidenciaDetailScreenState extends ConsumerState<AdminIncidenciaDetailScreen> {
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
      appBar: AppBar(title: const Text('Detalles de Incidencia')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth > 800;
          return Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isDesktop ? 40 : 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.incidencia.image != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.network(
                  '$baseUploadUrl${widget.incidencia.image}',
                  width: double.infinity,
                  height: isDesktop ? 450 : 250,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 24),
            
            if (widget.incidencia.latitud != null && widget.incidencia.longitud != null)
              Container(
                height: isDesktop ? 400 : 200,
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
            
            // Sección de Asignación de Técnico
            Text(
              "Asignar Técnico",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ref.watch(techniciansProvider).when(
              data: (techs) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: widget.incidencia.usuarioTecnicoId,
                    hint: const Text('Seleccionar técnico'),
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem<String>(
                        value: '',
                        child: Text('Sin asignar (Quitar técnico)', style: TextStyle(color: Colors.redAccent)),
                      ),
                      ...techs.map((t) => DropdownMenuItem(
                        value: t.uid,
                        child: Text(t.nombre ?? 'Sin nombre'),
                      )),
                    ],
                    onChanged: (val) {
                      ref.read(adminControllerProvider.notifier).assignTechnician(
                        int.parse(widget.incidencia.id), 
                        val ?? ''
                      ).then((_) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Asignación actualizada correctamente'))
                        );
                        Navigator.pop(context);
                      });
                    },
                  ),
                ),
              ),
              loading: () => const LinearProgressIndicator(),
              error: (e, st) => Text('Error al cargar técnicos: $e'),
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
              ),
            ),
            
            const SizedBox(height: 24),
            Text(
              "Cambiar Estado",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ref.watch(estadosProvider).when(
              data: (estados) => Wrap(
                spacing: 8,
                runSpacing: 8,
                children: estados.map((e) => _StatusButton(
                  statusId: e.id,
                  currentStatusId: widget.incidencia.estadoId,
                  label: e.nombre,
                  color: _getStatusColor(e.id),
                  onPressed: () => _updateStatus(e.id),
                )).toList(),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Text('Error al cargar estados: $e'),
            ),
          ],
        ),
      ),
    ),
  );
},
),
);
  }

  Color _getStatusColor(int statusId) {
    switch (statusId) {
      case 1: return Colors.orange;
      case 2: return Colors.blue;
      case 3: return Colors.green;
      case 4: return Colors.orange[800]!;
      case 5: return Colors.redAccent;
      default: return Colors.blueGrey;
    }
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
          const SnackBar(content: Text('Estado actualizado correctamente')),
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
      child: Text(label, style: const TextStyle(fontSize: 11)),
    );
  }
}

import 'package:ayuntamiento_incidencias/src/features/incidencias/presentation/incidencia_controller.dart';
import 'package:ayuntamiento_incidencias/src/features/incidencias/domain/incidencia.dart';
import 'package:ayuntamiento_incidencias/src/features/incidencias/presentation/edit_incidencia_screen.dart';
import 'package:ayuntamiento_incidencias/src/features/auth/data/auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class IncidenciaCard extends ConsumerWidget {
  final Incidencia incidencia;
  final VoidCallback? onTap;

  const IncidenciaCard({
    super.key,
    required this.incidencia,
    this.onTap,
  });

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

  String _getStatusText(String? statusName) {
    if (statusName == null) return 'ABIERTA';
    if (statusName.toLowerCase().contains('proceso')) return 'EN PROCESO';
    if (statusName.toLowerCase().contains('resuelta') && !statusName.toLowerCase().contains('no')) return 'RESUELTA';
    if (statusName.toLowerCase().contains('no resuelta')) return 'NO RESUELTA';
    if (statusName.toLowerCase().contains('error') || statusName.toLowerCase().contains('inválida')) return 'ERROR / INVÁLIDA';
    return statusName.toUpperCase();
  }

  Future<void> _showDeleteDialog(BuildContext context, WidgetRef ref) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Borrar incidencia?'),
        content: const Text('Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCELAR'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(incidenciaControllerProvider.notifier).deleteIncidencia(incidencia.id);
            },
            child: const Text('BORRAR', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const String baseUploadUrl = 'https://alumno23.fpcantillana.org/uploads/';
    
    final isTechnicianReport = incidencia.rolCreadorId == 2;
    final currentUser = ref.watch(authStateProvider);
    final isAdminOrTech = currentUser?.rolId == 2 || currentUser?.rolId == 3;
    final isOwner = currentUser?.uid == incidencia.usuarioId;
    final isFinalState = incidencia.estadoId >= 3;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isTechnicianReport 
          ? BorderSide(color: Colors.blue[900]!, width: 2) 
          : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (incidencia.image != null)
              Image.network(
                '$baseUploadUrl${incidencia.image}',
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 160,
                  color: Colors.grey[200],
                  child: const Icon(Icons.broken_image_outlined, size: 50),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getStatusColor(incidencia.estadoId).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _getStatusText(incidencia.estadoNombre).toUpperCase(),
                                style: TextStyle(
                                  color: _getStatusColor(incidencia.estadoId),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (isTechnicianReport)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.blue[900]?.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.blue[900]!, width: 1),
                                ),
                                child: Text(
                                  'REPORTE TÉCNICO',
                                  style: TextStyle(
                                    color: Colors.blue[900],
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (incidencia.estadoId == 1 && isOwner) ...[
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditIncidenciaScreen(incidencia: incidencia),
                              ),
                            );
                          },
                          icon: const Icon(Icons.edit_note, color: Colors.blue),
                          tooltip: 'Editar incidencia',
                        ),
                      ],
                      if ((isOwner && (incidencia.estadoId == 1 || isFinalState)) || (isAdminOrTech && isFinalState)) ...[
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          onPressed: () => _showDeleteDialog(context, ref),
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          tooltip: 'Borrar incidencia',
                        ),
                      ],
                      Text(
                        DateFormat('dd/MM/yyyy HH:mm').format(incidencia.fechaCreacion),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    incidencia.titulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    incidencia.descripcion,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.category_outlined, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          incidencia.categoriaNombre ?? 'Sin categoría',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                        ),
                        if (incidencia.tecnicoNombre != null) ...[
                          const SizedBox(width: 16),
                          Icon(Icons.engineering_outlined, size: 16, color: Colors.blue[700]),
                          const SizedBox(width: 4),
                          Text(
                            incidencia.tecnicoNombre!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.blue[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

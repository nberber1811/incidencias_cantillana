import 'package:ayuntamiento_incidencias/src/features/incidencias/domain/incidencia.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class IncidenciaCard extends StatelessWidget {
  final Incidencia incidencia;
  final VoidCallback? onTap;

  const IncidenciaCard({
    super.key,
    required this.incidencia,
    this.onTap,
  });

  Color _getStatusColor(IncidenciaStatus status) {
    switch (status) {
      case IncidenciaStatus.pending:
        return Colors.orange;
      case IncidenciaStatus.inProgress:
        return Colors.blue;
      case IncidenciaStatus.resolved:
        return Colors.green;
    }
  }

  String _getStatusText(IncidenciaStatus status) {
    switch (status) {
      case IncidenciaStatus.pending:
        return 'Pendiente';
      case IncidenciaStatus.inProgress:
        return 'En proceso';
      case IncidenciaStatus.resolved:
        return 'Resuelta';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (incidencia.imageUrl != null)
              Image.network(
                incidencia.imageUrl!,
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
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(incidencia.status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _getStatusText(incidencia.status).toUpperCase(),
                          style: TextStyle(
                            color: _getStatusColor(incidencia.status),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        DateFormat('dd/MM/yyyy HH:mm').format(incidencia.createdAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    incidencia.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    incidencia.description,
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
                        incidencia.category,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                      ),
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

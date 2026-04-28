import 'package:ayuntamiento_incidencias/src/features/incidencias/domain/incidencia.dart';
import 'package:flutter/material.dart';
import 'package:ayuntamiento_incidencias/src/features/incidencias/presentation/widgets/html_map_widget.dart';
import 'package:intl/intl.dart';

class IncidenciaDetailScreen extends StatelessWidget {
  final Incidencia incidencia;
  const IncidenciaDetailScreen({super.key, required this.incidencia});

  @override
  Widget build(BuildContext context) {
    const String baseUploadUrl = 'https://alumno23.fpcantillana.org/uploads/';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de Incidencia')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth > 800;
          final double horizontalPadding = isDesktop ? 40 : 24;
          
          return Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: SingleChildScrollView(
                padding: EdgeInsets.all(horizontalPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (incidencia.image != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.network(
                          '$baseUploadUrl${incidencia.image}',
                          width: double.infinity,
                          height: isDesktop ? 450 : 250,
                          fit: BoxFit.cover,
                        ),
                      ),
                    const SizedBox(height: 24),
                    
                    // Mapa o Dirección
                    if (incidencia.latitud != null && incidencia.longitud != null)
                      Container(
                        height: isDesktop ? 400 : 200,
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: HtmlMapWidget(
                            lat: incidencia.latitud!,
                            lng: incidencia.longitud!,
                            incidencias: [incidencia],
                          ),
                        ),
                      )
                    else if (incidencia.direccion != null && incidencia.direccion!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[300]!,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.redAccent),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                incidencia.direccion!,
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _StatusBadge(incidencia: incidencia),
                        Text(
                          DateFormat('dd/MM/yyyy HH:mm').format(incidencia.fechaCreacion),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      incidencia.titulo,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      incidencia.descripcion,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: isDark ? Colors.grey[300] : Colors.black87,
                      ),
                    ),
                    
                    if (incidencia.comentarioTecnico != null && incidencia.comentarioTecnico!.isNotEmpty) ...[
                      const SizedBox(height: 32),
                      const Divider(),
                      const SizedBox(height: 24),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.blueAccent.withOpacity(0.1) : Colors.blue[50],
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isDark ? Colors.blueAccent.withOpacity(0.3) : Colors.blue[100]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.comment_bank_outlined, color: isDark ? Colors.blue[200] : Colors.blue[800]),
                                const SizedBox(width: 12),
                                Text(
                                  "Respuesta Municipal",
                                  style: TextStyle(
                                    color: isDark ? Colors.blue[100] : Colors.blue[900],
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              incidencia.comentarioTecnico!,
                              style: TextStyle(
                                color: isDark ? Colors.blue[50] : Colors.blue[800],
                                fontSize: 16,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final Incidencia incidencia;
  const _StatusBadge({required this.incidencia});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (incidencia.estadoId) {
      case 1: color = Colors.orange; break;
      case 2: color = Colors.blue; break;
      case 3: color = Colors.green; break;
      case 4: color = Colors.orange[800]!; break;
      case 5: color = Colors.redAccent; break;
      default: color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        incidencia.estadoNombre?.toUpperCase() ?? 'ABIERTA',
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}

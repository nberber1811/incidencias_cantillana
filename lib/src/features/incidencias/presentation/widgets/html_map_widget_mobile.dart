import 'package:flutter/material.dart';
import 'package:ayuntamiento_incidencias/src/features/incidencias/domain/incidencia.dart';
import 'package:url_launcher/url_launcher.dart';

class HtmlMapWidget extends StatelessWidget {
  final double lat;
  final double lng;
  final double zoom;
  final List<Incidencia> incidencias;

  const HtmlMapWidget({
    super.key,
    required this.lat,
    required this.lng,
    this.zoom = 15,
    this.incidencias = const [],
  });

  Future<void> _launchWebMap() async {
    final Uri url = Uri.parse('https://alumno23.fpcantillana.org/');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('No se pudo abrir $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.map_outlined, size: 48, color: Colors.blue[800]),
          const SizedBox(height: 12),
          Text(
            'Mapa Interactivo',
            style: TextStyle(
              color: Colors.blue[900],
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Para ver el mapa detallado, pulsa el botón para abrir la versión Web.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.blueGrey, fontSize: 13),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _launchWebMap,
            icon: const Icon(Icons.open_in_browser),
            label: const Text('Ver Mapa en Web'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[800],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}

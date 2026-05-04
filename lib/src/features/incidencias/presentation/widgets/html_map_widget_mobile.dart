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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.map_outlined, size: 32, color: Colors.blue[800]),
          const SizedBox(height: 8),
          Text(
            'Mapa Interactivo',
            style: TextStyle(
              color: Colors.blue[900],
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Para ver el mapa detallado, pulsa el botón.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.blueGrey, fontSize: 12),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _launchWebMap,
              icon: const Icon(Icons.open_in_browser, size: 18),
              label: const Text('Abrir Mapa Web', style: TextStyle(fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[800],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

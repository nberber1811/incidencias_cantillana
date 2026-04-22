import 'package:flutter/material.dart';
import 'package:ayuntamiento_incidencias/src/features/incidencias/domain/incidencia.dart';

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

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.map, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('El mapa interactivo solo está disponible en la versión Web.'),
        ],
      ),
    );
  }
}

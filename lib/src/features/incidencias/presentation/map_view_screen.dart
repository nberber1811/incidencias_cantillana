import 'package:ayuntamiento_incidencias/src/features/incidencias/data/incidencia_repository.dart';
import 'package:ayuntamiento_incidencias/src/features/incidencias/domain/incidencia.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ayuntamiento_incidencias/src/features/incidencias/presentation/widgets/html_map_widget.dart';

class MapViewScreen extends ConsumerStatefulWidget {
  const MapViewScreen({super.key});

  @override
  ConsumerState<MapViewScreen> createState() => _MapViewScreenState();
}

class _MapViewScreenState extends ConsumerState<MapViewScreen> {
  final double _lat = 37.6083; // Cantillana centre
  final double _lng = -5.7144;

  @override
  Widget build(BuildContext context) {
    final incidenciasAsync = ref.watch(allIncidenciasStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mapa de Incidencias')),
      body: incidenciasAsync.when(
        data: (incidencias) {
          return HtmlMapWidget(
            lat: _lat,
            lng: _lng,
            incidencias: incidencias,
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

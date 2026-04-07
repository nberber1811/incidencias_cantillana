import 'package:ayuntamiento_incidencias/src/features/incidencias/data/incidencia_repository.dart';
import 'package:ayuntamiento_incidencias/src/features/incidencias/domain/incidencia.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapViewScreen extends ConsumerStatefulWidget {
  const MapViewScreen({super.key});

  @override
  ConsumerState<MapViewScreen> createState() => _MapViewScreenState();
}

class _MapViewScreenState extends ConsumerState<MapViewScreen> {
  late GoogleMapController _mapController;
  final LatLng _initialPosition = const LatLng(37.6083, -5.7144); // Default to Cantillana

  Set<Marker> _createMarkers(List<Incidencia> incidencias) {
    return incidencias
        .where((i) => i.latitude != null && i.longitude != null)
        .map((i) {
      return Marker(
        markerId: MarkerId(i.id),
        position: LatLng(i.latitude!, i.longitude!),
        infoWindow: InfoWindow(
          title: i.title,
          snippet: i.category,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          i.status == IncidenciaStatus.resolved
              ? BitmapDescriptor.hueGreen
              : (i.status == IncidenciaStatus.inProgress 
                  ? BitmapDescriptor.hueBlue 
                  : BitmapDescriptor.hueOrange),
        ),
      );
    }).toSet();
  }

  @override
  Widget build(BuildContext context) {
    // We watch all incidencias for the map, or we could filter based on role if needed
    // For now, let's show all for simplicity or just the user's if they are a citizen.
    // Let's assume this is a general view or admin view.
    final incidenciasAsync = ref.watch(StreamProvider((ref) => ref.watch(incidenciaRepositoryProvider).watchAllIncidencias()));

    return Scaffold(
      appBar: AppBar(title: const Text('Mapa de Incidencias')),
      body: incidenciasAsync.when(
        data: (incidencias) {
          return GoogleMap(
            onMapCreated: (controller) => _mapController = controller,
            initialCameraPosition: CameraPosition(
              target: _initialPosition,
              zoom: 14,
            ),
            markers: _createMarkers(incidencias),
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

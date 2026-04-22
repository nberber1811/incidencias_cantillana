import 'dart:async';
import 'package:ayuntamiento_incidencias/src/features/incidencias/domain/incidencia.dart';
import 'package:flutter/material.dart';
import 'dart:ui_web' as ui;
import 'package:web/web.dart' as web;

class HtmlMapWidget extends StatefulWidget {
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
  State<HtmlMapWidget> createState() => _HtmlMapWidgetState();
}

class _HtmlMapWidgetState extends State<HtmlMapWidget> {
  late String _viewId;
  static int _idCounter = 0;

  @override
  void initState() {
    super.initState();
    _viewId = 'map-view-${_idCounter++}';
    
    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(_viewId, (int viewId) {
      final div = web.HTMLDivElement()
        ..id = _viewId
        ..style.width = '100%'
        ..style.height = '100%';

      // We wait for the element to be inserted in the DOM to initialize Leaflet
      Timer(const Duration(milliseconds: 100), () {
        _initLeaflet();
      });

      return div;
    });
  }

  void _initLeaflet() {
    // Inyectamos script de inicialización
    final script = web.HTMLScriptElement()
      ..text = '''
        (function() {
          var container = document.getElementById('$_viewId');
          if (!container) return;
          
          var map = L.map('$_viewId').setView([${widget.lat}, ${widget.lng}], ${widget.zoom});
          L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
              maxZoom: 19,
              attribution: '© OpenStreetMap'
          }).addTo(map);

          var icon = L.icon({
              iconUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon.png',
              shadowUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-shadow.png',
              iconSize: [25, 41],
              iconAnchor: [12, 41],
              popupAnchor: [1, -34],
              shadowSize: [41, 41]
          });

          ${widget.incidencias.map((i) => '''
            L.marker([${i.latitud}, ${i.longitud}], {icon: icon})
              .addTo(map)
              .bindPopup('<b>${i.titulo}</b><br>${i.categoriaNombre ?? ''}');
          ''').join('\n')}
        })();
      ''';
    web.document.body?.append(script);
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: _viewId);
  }
}

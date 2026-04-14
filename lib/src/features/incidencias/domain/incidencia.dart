


class Incidencia {
  final String id;
  final String usuarioId;
  final String titulo;
  final String descripcion;
  final String? image;
  final DateTime fechaCreacion;
  final DateTime? fechaCierre;
  final double? latitud;
  final double? longitud;
  final String? direccion;
  final int? categoriaId;
  final String? categoriaNombre;
  final int estadoId;
  final String? estadoNombre;

  Incidencia({
    required this.id,
    required this.usuarioId,
    required this.titulo,
    required this.descripcion,
    this.image,
    required this.fechaCreacion,
    this.fechaCierre,
    this.latitud,
    this.longitud,
    this.direccion,
    this.categoriaId,
    this.categoriaNombre,
    this.estadoId = 1,
    this.estadoNombre,
  });

  factory Incidencia.fromJson(Map<String, dynamic> json) {
    return Incidencia(
      id: json['id']?.toString() ?? '',
      usuarioId: json['usuario_id']?.toString() ?? '',
      titulo: json['titulo'] ?? '',
      descripcion: json['descripcion'] ?? '',
      image: json['image'],
      latitud: double.tryParse(json['latitud']?.toString() ?? ''),
      longitud: double.tryParse(json['longitud']?.toString() ?? ''),
      direccion: json['direccion'],
      categoriaId: json['categoria_id'],
      categoriaNombre: json['categoriaNombre'],
      estadoId: json['estado_id'] ?? 1,
      estadoNombre: json['estadoNombre'] ?? 'Abierta',
      fechaCreacion: json['fecha_creacion'] != null 
          ? DateTime.parse(json['fecha_creacion'] as String)
          : DateTime.now(),
      fechaCierre: json['fecha_cierre'] != null
          ? DateTime.parse(json['fecha_cierre'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'usuario_id': usuarioId,
      'titulo': titulo,
      'descripcion': descripcion,
      'image': image,
      'latitud': latitud,
      'longitud': longitud,
      'direccion': direccion,
      'categoria_id': categoriaId,
      'estado_id': estadoId,
      'fecha_creacion': fechaCreacion.toIso8601String(),
    };
  }
}

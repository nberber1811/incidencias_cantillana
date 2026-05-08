
class HistorialItem {
  final int id;
  final DateTime fechaCambio;
  final int? estadoAnterior;
  final int? estadoNuevo;
  final String? estadoAnteriorNombre;
  final String? estadoNuevoNombre;
  final int? usuarioId;
  final String? usuarioNombre;
  final int? incidenciaId;
  final String? incidenciaTitulo;

  HistorialItem({
    required this.id,
    required this.fechaCambio,
    this.estadoAnterior,
    this.estadoNuevo,
    this.estadoAnteriorNombre,
    this.estadoNuevoNombre,
    this.usuarioId,
    this.usuarioNombre,
    this.incidenciaId,
    this.incidenciaTitulo,
  });

  factory HistorialItem.fromJson(Map<String, dynamic> json) {
    return HistorialItem(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      fechaCambio: DateTime.parse(json['fecha_cambio']),
      estadoAnterior: json['estado_anterior'],
      estadoNuevo: json['estado_nuevo'],
      estadoAnteriorNombre: json['estadoAnteriorNombre'],
      estadoNuevoNombre: json['estadoNuevoNombre'],
      usuarioId: json['usuario_id'],
      usuarioNombre: json['usuarioNombre'],
      incidenciaId: json['incidencia_id'],
      incidenciaTitulo: json['incidenciaTitulo'],
    );
  }
}

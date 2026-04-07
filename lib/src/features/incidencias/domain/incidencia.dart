
enum IncidenciaStatus { pending, inProgress, resolved }

class Incidencia {
  final String id;
  final String userId;
  final String title;
  final String description;
  final String? imageUrl;
  final double? latitude;
  final double? longitude;
  final String category;
  final IncidenciaStatus status;
  final DateTime createdAt;

  Incidencia({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    this.imageUrl,
    this.latitude,
    this.longitude,
    required this.category,
    this.status = IncidenciaStatus.pending,
    required this.createdAt,
  });

  factory Incidencia.fromJson(Map<String, dynamic> json) {
    return Incidencia(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'],
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      category: json['category'] ?? 'Otros',
      status: IncidenciaStatus.values.firstWhere(
        (e) => e.name == (json['status'] ?? 'pending'),
        orElse: () => IncidenciaStatus.pending,
      ),
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'latitude': latitude,
      'longitude': longitude,
      'category': category,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

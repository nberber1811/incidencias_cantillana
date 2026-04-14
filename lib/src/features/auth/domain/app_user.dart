enum UserRole { ciudadano, tecnico, administrador }

class AppUser {
  final String uid;
  final String email;
  final String? nombre;
  final String? telefono;
  final int rolId;

  AppUser({
    required this.uid,
    required this.email,
    this.nombre,
    this.telefono,
    this.rolId = 1,
  });

  UserRole get role {
    switch (rolId) {
      case 2: return UserRole.tecnico;
      case 3: return UserRole.administrador;
      default: return UserRole.ciudadano;
    }
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      uid: json['uid']?.toString() ?? '',
      email: json['email'] ?? '',
      nombre: json['nombre'],
      telefono: json['telefono'],
      rolId: json['rol_id'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'nombre': nombre,
      'telefono': telefono,
      'rol_id': rolId,
    };
  }
}

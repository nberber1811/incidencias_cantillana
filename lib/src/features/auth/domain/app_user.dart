enum UserRole { citizen, admin }

class AppUser {
  final String uid;
  final String email;
  final String? nombre;
  final UserRole role;

  AppUser({
    required this.uid,
    required this.email,
    this.nombre,
    this.role = UserRole.citizen,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      uid: json['uid'] ?? '',
      email: json['email'] ?? '',
      nombre: json['nombre'],
      role: UserRole.values.firstWhere(
        (e) => e.name == (json['role'] ?? 'citizen'),
        orElse: () => UserRole.citizen,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'nombre': nombre,
      'role': role.name,
    };
  }
}

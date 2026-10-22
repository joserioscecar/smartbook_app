class LoginResponse {
  final String accessToken;
  final int expiresAt;
  final Usuario usuario;

  const LoginResponse({
    required this.accessToken,
    required this.expiresAt,
    required this.usuario,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) => LoginResponse(
    accessToken: json['accessToken'] as String,
    expiresAt: json['expiresAt'] as int,
    usuario: Usuario.fromJson(json['usuario'] as Map<String, dynamic>),
  );
}

class Usuario {
  final String identificacion;
  final String nombres;
  final String email;
  final String rol;

  const Usuario({
    required this.identificacion,
    required this.nombres,
    required this.email,
    required this.rol,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) => Usuario(
    identificacion: json['identificacion'] as String,
    nombres: json['nombres'] as String,
    email: json['email'] as String,
    rol: json['rol'] as String,
  );
}

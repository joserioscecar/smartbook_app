class LoginRequest {
  const LoginRequest({required this.correo, required this.password});
  final String correo;
  final String password;

  Map<String, dynamic> toJson() => {'correo': correo, 'password': password};
}

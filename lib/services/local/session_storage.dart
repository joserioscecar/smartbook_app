/// Contrato para implementar almacenamiento seguro del token en el dispositivo.
/// Las contraseñas nunca deben guardarse localmente.
abstract interface class SessionStorage {
  Future<void> saveToken(String token);
  Future<String?> readToken();
  Future<void> clear();
}

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'session_storage.dart';

class SecureStorageService implements SessionStorage {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  Future<void> saveToken(String token) async {
    await _storage.write(key: 'token', value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'token');
  }

  @override
  Future<String?> readToken() => getToken();

  Future<void> deleteToken() async {
    await _storage.delete(key: 'token');
  }

  @override
  Future<void> clear() => deleteToken();
}

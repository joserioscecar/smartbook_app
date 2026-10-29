import 'package:smartbook_app/config/app_config.dart';
import 'package:smartbook_app/models/login/login_request.dart';
import 'package:smartbook_app/models/login/login_response.dart';
import 'package:smartbook_app/services/local/secure_storage_service.dart';
import 'package:smartbook_app/services/local/user_preferences_service.dart';
import 'package:smartbook_app/services/remote/api_service.dart';

class LoginService {
  final _api = ApiService(baseUrl: AppConfig.apiBaseUrl);
  final _storage = SecureStorageService();
  final pfs = UsuarioPreferencesService();

  Future<bool> login(LoginRequest request) async {
    final response = await _api.post<LoginResponse>(
      '/Seguridad/iniciar-sesion',
      body: request.toJson(),
      fromJson: LoginResponse.fromJson,
    );

    final login = response.data;
    if (!response.isSuccess || login == null) return false;

    await _storage.saveToken(login.accessToken);
    await pfs.guardarUsuario(
      id: login.usuario.identificacion,
      nombre: login.usuario.nombres,
      correo: login.usuario.email,
    );

    return true;
  }
}

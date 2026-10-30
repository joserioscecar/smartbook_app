import 'package:smartbook_app/config/app_config.dart';
import 'package:smartbook_app/models/login/login_request.dart';
import 'package:smartbook_app/models/login/login_response.dart';
import 'package:smartbook_app/services/local/secure_storage_service.dart';
import 'package:smartbook_app/services/local/user_preferences_service.dart';
import 'package:smartbook_app/services/remote/api_service.dart';

class LoginService {
  final _api = ApiService(
    baseUrl: AppConfig.apiBaseUrl,
    timeout: const Duration(seconds: 90),
  );
  final _storage = SecureStorageService();
  final pfs = UsuarioPreferencesService();

  Future<bool> login(LoginRequest request) async {
    final response = await _api.post<LoginResponse>(
      '/Seguridad/iniciar-sesion',
      body: request.toJson(),
      fromJson: LoginResponse.fromJson,
    );

    if (!response.isSuccess) {
      throw ApiException(
        response.message ?? 'Authentication failed.',
        statusCode: response.statusCode,
        data: response.rawData,
      );
    }

    final login = response.data;
    if (login == null) {
      throw ApiParseException(
        'The login response did not contain authentication data.',
        statusCode: response.statusCode,
      );
    }

    await _storage.saveToken(login.accessToken);
    await pfs.guardarUsuario(
      id: login.usuario.identificacion,
      nombre: login.usuario.nombres,
      correo: login.usuario.email,
    );

    return true;
  }
}

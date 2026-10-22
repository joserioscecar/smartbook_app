import 'package:smartbook_app/config/app_config.dart';
import 'package:smartbook_app/models/login/login_request.dart';
import 'package:smartbook_app/models/login/login_response.dart';
import 'package:smartbook_app/services/remote/api_service.dart';

class LoginService {
  final _api = ApiService(baseUrl: AppConfig.apiBaseUrl);

  Future<LoginResponse> login(LoginRequest request) async {
    var response = await _api.post(
      "/Seguridad/iniciar-sesion",
      body: request.toJson(),
    );

    return LoginResponse.fromJson(response);
  }
}

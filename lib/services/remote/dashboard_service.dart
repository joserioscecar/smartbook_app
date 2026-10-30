import '../../config/app_config.dart';
import '../../models/dashboard/dashboard_response.dart';
import '../local/secure_storage_service.dart';
import 'api_service.dart';

class DashboardService {
  final _api = ApiService(baseUrl: AppConfig.apiBaseUrl);
  final _storage = SecureStorageService();

  Future<ApiResponse<DashboardResponse>> consultarDashboard() async {
    final token = await _storage.readToken();
    if (token == null || token.isEmpty) {
      throw const SessionException(
        'No hay una sesión activa. Inicia sesión para consultar el dashboard.',
      );
    }
    return _api.get<DashboardResponse>(
      '/dashboard',
      headers: {'Authorization': 'Bearer $token'},
      fromJson: DashboardResponse.fromJson,
    );
  }
}

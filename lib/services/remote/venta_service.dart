import '../../config/app_config.dart';
import '../../extensions/date_time_extensions.dart';
import '../../models/venta/crear_venta_request.dart';
import '../../models/venta/venta_response.dart';
import '../../models/venta/venta_resumen_response.dart';
import '../local/secure_storage_service.dart';
import '../local/session_storage.dart';
import 'api_service.dart';

class VentaService {
  VentaService({ApiService? api, SessionStorage? storage}) {
    _api = api ?? ApiService(baseUrl: AppConfig.apiBaseUrl);
    _storage = storage ?? SecureStorageService();
  }

  late final ApiService _api;
  late final SessionStorage _storage;

  Future<ApiResponse<List<VentaResumenResponse>>> listarVentas({
    DateTime? desde,
    DateTime? hasta,
  }) async {
    final token = await _storage.readToken();
    if (token == null || token.isEmpty) {
      throw const SessionException('No active session. Sign in to list sales.');
    }
    return _api.get<List<VentaResumenResponse>>(
      '/Ventas/',
      queryParameters: {
        if (desde != null) 'desde': desde.toIsoDateString(),
        if (hasta != null) 'hasta': hasta.toIsoDateString(),
      },
      headers: {'Authorization': 'Bearer $token'},
      fromJsonList: VentaResumenResponse.fromJsonList,
    );
  }

  Future<ApiResponse<void>> crearVenta(CrearVentaRequest request) async {
    final token = await _storage.readToken();
    if (token == null || token.isEmpty) {
      throw const SessionException(
        'No active session. Sign in to create a sale.',
      );
    }
    return _api.post<void>(
      '/Ventas',
      headers: {'Authorization': 'Bearer $token'},
      body: request.toJson(),
    );
  }

  Future<ApiResponse<VentaResponse>> consultarVenta(int id) async {
    if (id <= 0) throw ArgumentError.value(id, 'id', 'Debe ser positivo');
    final token = await _storage.readToken();
    if (token == null || token.isEmpty) {
      throw const SessionException(
        'No hay una sesión activa. Inicia sesión para consultar una venta.',
      );
    }
    return _api.get<VentaResponse>(
      '/ventas/$id',
      headers: {'Authorization': 'Bearer $token'},
      fromJson: VentaResponse.fromJson,
    );
  }
}

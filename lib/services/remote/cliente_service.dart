import 'package:smartbook_app/config/app_config.dart';
import 'package:smartbook_app/models/cliente/cliente_response.dart';
import 'package:smartbook_app/models/cliente/editar_cliente_request.dart';
import 'package:smartbook_app/services/local/secure_storage_service.dart';
import 'package:smartbook_app/services/local/session_storage.dart';
import 'package:smartbook_app/services/remote/api_service.dart';

class ClienteService {
  ClienteService({ApiService? api, SessionStorage? storage})
    : _api = api ?? ApiService(baseUrl: AppConfig.apiBaseUrl),
      _storage = storage ?? SecureStorageService();

  final ApiService _api;
  final SessionStorage _storage;

  Future<ApiResponse<List<ClienteResponse>>> listarClientes() async {
    final token = await _storage.readToken();
    if (token == null || token.isEmpty) {
      throw const SessionException(
        'No hay una sesión activa. Inicia sesión para listar los clientes.',
      );
    }
    return _api.get<List<ClienteResponse>>(
      '/Clientes',
      headers: {'Authorization': 'Bearer $token'},
      fromJsonList: ClienteResponse.fromJsonList,
    );
  }

  Future<ApiResponse<void>> editarCliente(
    String identificacion,
    EditarClienteRequest request,
  ) async {
    if (identificacion.trim().isEmpty) {
      throw ArgumentError.value(
        identificacion,
        'identificacion',
        'Es requerida',
      );
    }
    final token = await _storage.readToken();
    if (token == null || token.isEmpty) {
      throw const SessionException(
        'No hay una sesión activa. Inicia sesión para editar un cliente.',
      );
    }

    return _api.put<void>(
      '/Clientes/${Uri.encodeComponent(identificacion.trim())}',
      headers: {'Authorization': 'Bearer $token'},
      body: request.toJson(),
      ignoreResponseBody: true,
    );
  }
}

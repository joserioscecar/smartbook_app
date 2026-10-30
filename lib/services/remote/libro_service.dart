import 'package:smartbook_app/config/app_config.dart';
import 'package:smartbook_app/models/libro/libro_request.dart';
import 'package:smartbook_app/models/libro/libro_response.dart';
import 'package:smartbook_app/services/local/secure_storage_service.dart';
import 'package:smartbook_app/services/remote/api_service.dart';

class LibroService {
  final _api = ApiService(baseUrl: AppConfig.apiBaseUrl);
  final _storage = SecureStorageService();

  Future<ApiResponse<List<LibroResponse>>> listarLibros() async {
    final token = await _storage.readToken();
    if (token == null || token.isEmpty) {
      throw const SessionException(
        'No hay una sesión activa. Inicia sesión para listar los libros.',
      );
    }
    return _api.get<List<LibroResponse>>(
      '/Libros',
      headers: {'Authorization': 'Bearer $token'},
      fromJsonList: LibroResponse.fromJsonList,
    );
  }

  Future<ApiResponse<LibroResponse>> consultarLibro(int id) async {
    final token = await _storage.readToken();
    if (token == null || token.isEmpty) {
      throw const SessionException(
        'No hay una sesión activa. Inicia sesión para consultar un libro.',
      );
    }
    return _api.get<LibroResponse>(
      '/Libros/$id',
      headers: {'Authorization': 'Bearer $token'},
      fromJson: LibroResponse.fromJson,
    );
  }

  Future<ApiResponse<LibroResponse>> crearLibro(
    CrearLibroRequest request,
  ) async {
    final token = await _storage.readToken();
    if (token == null || token.isEmpty) {
      throw const SessionException(
        'No hay una sesión activa. Inicia sesión para crear un libro.',
      );
    }
    return _api.post<LibroResponse>(
      '/Libros',
      headers: {'Authorization': 'Bearer $token'},
      body: request.toJson(),
      fromJson: LibroResponse.fromJson,
    );
  }

  Future<ApiResponse> eliminarLibro(int id) async {
    final token = await _storage.readToken();
    if (token == null || token.isEmpty) {
      throw const SessionException(
        'No hay una sesión activa. Inicia sesión para eliminar un libro.',
      );
    }

    return _api.delete(
      '/Libros/$id',
      headers: {'Authorization': 'Bearer $token'},
    );
  }
}

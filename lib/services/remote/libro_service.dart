import 'package:smartbook_app/config/app_config.dart';
import 'package:smartbook_app/services/remote/api_service.dart';

class LibroService {
  final _api = ApiService(baseUrl: AppConfig.apiBaseUrl);

  void registrarLibro() {}
}

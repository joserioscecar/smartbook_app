import 'package:smartbook_app/config/app_config.dart';
import 'package:smartbook_app/services/remote/api_service.dart';

class ClienteService {
  final _api = ApiService(baseUrl: AppConfig.apiBaseUrl);
}

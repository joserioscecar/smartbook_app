import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smartbook_app/services/remote/api_service.dart';

void main() {
  group('ApiService HTTP status handling', () {
    test('returns non-success HTTP status without throwing', () async {
      final client = MockClient(
        (_) async => http.Response('{"message":"Libro no encontrado"}', 404),
      );
      addTearDown(client.close);
      final api = ApiService(
        baseUrl: 'https://example.test/api',
        client: client,
        enableLogs: false,
      );

      final response = await api.get<dynamic>('/Libros/99');

      expect(response.statusCode, 404);
      expect(response.isSuccess, isFalse);
      expect(response.message, 'Libro no encontrado');
      expect(response.rawData, {'message': 'Libro no encontrado'});
    });

    test('parses data for successful HTTP responses', () async {
      final client = MockClient(
        (_) async => http.Response('{"value":42}', 200),
      );
      addTearDown(client.close);
      final api = ApiService(
        baseUrl: 'https://example.test/api',
        client: client,
        enableLogs: false,
      );

      final response = await api.get<Map<String, dynamic>>(
        '/recurso',
        fromJson: Map<String, dynamic>.from,
      );

      expect(response.statusCode, 200);
      expect(response.isSuccess, isTrue);
      expect(response.data, {'value': 42});
    });
  });
}

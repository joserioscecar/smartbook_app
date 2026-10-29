import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smartbook_app/models/cliente/editar_cliente_request.dart';
import 'package:smartbook_app/services/local/session_storage.dart';
import 'package:smartbook_app/services/remote/api_service.dart';
import 'package:smartbook_app/services/remote/cliente_service.dart';

class _MemorySessionStorage implements SessionStorage {
  _MemorySessionStorage(this.token);

  final String? token;

  @override
  Future<void> clear() async {}

  @override
  Future<String?> readToken() async => token;

  @override
  Future<void> saveToken(String token) async {}
}

void main() {
  group('ClienteService', () {
    test('sends the stored bearer token and update DTO when editing', () async {
      final client = MockClient((request) async {
        expect(request.method, 'PUT');
        expect(request.url.path, '/api/Clientes/1108762718');
        expect(request.headers['authorization'], 'Bearer saved-token');
        expect(
          jsonDecode(request.body),
          {
            'nombres': 'Ana Pérez',
            'email': 'ana@example.com',
            'celular': '3001234567',
          },
        );
        return http.Response('', 204);
      });
      addTearDown(client.close);
      final service = ClienteService(
        api: ApiService(
          baseUrl: 'https://example.test/api',
          client: client,
          enableLogs: false,
        ),
        storage: _MemorySessionStorage('saved-token'),
      );

      final response = await service.editarCliente(
        '1108762718',
        const EditarClienteRequest(
          nombres: 'Ana Pérez',
          email: 'ana@example.com',
          celular: '3001234567',
        ),
      );

      expect(response.statusCode, 204);
      expect(response.isSuccess, isTrue);
    });

    test('does not send an update without an active session', () async {
      var requestSent = false;
      final client = MockClient((_) async {
        requestSent = true;
        return http.Response('', 204);
      });
      addTearDown(client.close);
      final service = ClienteService(
        api: ApiService(
          baseUrl: 'https://example.test/api',
          client: client,
          enableLogs: false,
        ),
        storage: _MemorySessionStorage(null),
      );

      await expectLater(
        service.editarCliente(
          '1108762718',
          const EditarClienteRequest(
            nombres: 'Ana Pérez',
            email: 'ana@example.com',
            celular: '3001234567',
          ),
        ),
        throwsA(isA<SessionException>()),
      );
      expect(requestSent, isFalse);
    });
  });
}

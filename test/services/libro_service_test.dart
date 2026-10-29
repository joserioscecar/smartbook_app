import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smartbook_app/models/libro/libro_request.dart';
import 'package:smartbook_app/services/local/session_storage.dart';
import 'package:smartbook_app/services/remote/api_service.dart';
import 'package:smartbook_app/services/remote/libro_service.dart';

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
  group('LibroService session flow', () {
    test('sends the stored bearer token when listing books', () async {
      final client = MockClient((request) async {
        expect(request.headers['authorization'], 'Bearer saved-token');
        expect(request.url.path, '/api/Libros');
        return http.Response(
          '[{"id":1,"nombre":"Libro","nivel":"A1","stockTotal":4}]',
          200,
        );
      });
      addTearDown(client.close);
      final api = ApiService(
        baseUrl: 'https://example.test/api',
        client: client,
        enableLogs: false,
      );
      final service = LibroService(
        api: api,
        storage: _MemorySessionStorage('saved-token'),
      );

      final response = await service.listarLibros();

      expect(response.data, hasLength(1));
      expect(response.data!.single.nombre, 'Libro');
    });

    test('parses a single book and sends its bearer token', () async {
      final client = MockClient((request) async {
        expect(request.headers['authorization'], 'Bearer saved-token');
        expect(request.url.path, '/api/Libros/1');
        return http.Response(
          '{"id":90,"nombre":"Superminds 1","nivel":"Kids A1.1",'
          '"tipo":"StudentsBook","lote":20262,"stockTotal":986,'
          '"valorCompa":90000.00,"valorVentaPulico":100000.00}',
          200,
        );
      });
      addTearDown(client.close);
      final api = ApiService(
        baseUrl: 'https://example.test/api',
        client: client,
        enableLogs: false,
      );
      final service = LibroService(
        api: api,
        storage: _MemorySessionStorage('saved-token'),
      );

      final response = await service.consultarLibro(1);

      expect(response.data?.nombre, 'Superminds 1');
      expect(response.data?.tipo, 'StudentsBook');
      expect(response.data?.lote, 20262);
      expect(response.data?.stockTotal, 986);
      expect(response.data?.valorCompra, 90000.0);
      expect(response.data?.valorVentaPublico, 100000.0);
    });

    test('does not send a request without an active session', () async {
      var requestSent = false;
      final client = MockClient((_) async {
        requestSent = true;
        return http.Response('{}', 200);
      });
      addTearDown(client.close);
      final api = ApiService(
        baseUrl: 'https://example.test/api',
        client: client,
        enableLogs: false,
      );
      final service = LibroService(
        api: api,
        storage: _MemorySessionStorage(null),
      );

      await expectLater(
        service.listarLibros(),
        throwsA(
          isA<SessionException>().having(
            (error) => error.message,
            'message',
            contains('No hay una sesión activa'),
          ),
        ),
      );
      expect(requestSent, isFalse);
    });

    test('sends the token when creating a book', () async {
      final client = MockClient((request) async {
        expect(request.headers['authorization'], 'Bearer saved-token');
        expect(request.method, 'POST');
        expect(request.url.path, '/api/Libros');
        return http.Response(
          '{"id":90,"nombre":"Superminds 1","nivel":"Kids A1.1",'
          '"tipo":"StudentsBook","lote":20262,"stockTotal":986,'
          '"valorCompa":90000.00,"valorVentaPulico":100000.00}',
          201,
        );
      });
      addTearDown(client.close);
      final api = ApiService(
        baseUrl: 'https://example.test/api',
        client: client,
        enableLogs: false,
      );
      final service = LibroService(
        api: api,
        storage: _MemorySessionStorage('saved-token'),
      );

      final response = await service.crearLibro(
        const CrearLibroRequest(
          nombre: 'Libro',
          nivel: 'A1',
          tipo: 1,
          edicion: '1ra',
          unidades: 4,
          valorCompra: 10,
          valorVentaPublico: 15,
          lote: 'L1',
        ),
      );

      expect(response.statusCode, 201);
      expect(response.data?.id, 90);
      expect(response.data?.valorCompra, 90000.0);
      expect(response.data?.valorVentaPublico, 100000.0);
    });

    test('sends an authenticated DELETE request for a book ID', () async {
      final client = MockClient((request) async {
        expect(request.headers['authorization'], 'Bearer saved-token');
        expect(request.method, 'DELETE');
        expect(request.url.path, '/api/Libros/90');
        return http.Response('', 204);
      });
      addTearDown(client.close);
      final api = ApiService(
        baseUrl: 'https://example.test/api',
        client: client,
        enableLogs: false,
      );
      final service = LibroService(
        api: api,
        storage: _MemorySessionStorage('saved-token'),
      );

      final response = await service.eliminarLibro(90);

      expect(response.statusCode, 204);
      expect(response.isSuccess, isTrue);
    });
  });
}

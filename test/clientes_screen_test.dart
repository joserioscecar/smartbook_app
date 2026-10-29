import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smartbook_app/screens/clientes_screen.dart';
import 'package:smartbook_app/services/local/session_storage.dart';
import 'package:smartbook_app/services/remote/api_service.dart';
import 'package:smartbook_app/services/remote/cliente_service.dart';

class _MemorySessionStorage implements SessionStorage {
  @override
  Future<String?> readToken() async => 'test-token';
  @override
  Future<void> saveToken(String token) async {}
  @override
  Future<void> clear() async {}
}

Future<void> _montarLista(
  WidgetTester tester,
  Future<http.Response> Function(http.Request) responder,
) async {
  tester.view.physicalSize = const Size(800, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final client = MockClient((request) async {
    expect(request.headers['authorization'], 'Bearer test-token');
    return responder(request);
  });
  addTearDown(client.close);
  final service = ClienteService(
    api: ApiService(
      baseUrl: 'https://example.test/api',
      client: client,
      enableLogs: false,
    ),
    storage: _MemorySessionStorage(),
  );
  await tester.pumpWidget(MaterialApp(home: ClientesScreen(service: service)));
  await tester.pumpAndSettle();
}

Future<void> _editarNombre(WidgetTester tester, String nombres) async {
  await tester.tap(find.byTooltip('Editar cliente'));
  await tester.pumpAndSettle();
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Nombres'),
    nombres,
  );
}

Future<void> _guardar(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Guardar cambios'));
  await tester.tap(find.text('Guardar cambios'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'Actualizar solo el correo envía el valor nuevo y recarga la lista',
    (tester) async {
      var email = 'ana@example.com';
      var escrituras = 0;
      var lecturas = 0;
      await _montarLista(tester, (request) async {
        if (request.method == 'GET') {
          lecturas++;
          return http.Response(
            jsonEncode([
              {
                'identificacion': '123456',
                'nombres': 'Ana Original',
                'email': email,
                'celular': '3001234567',
              },
            ]),
            200,
          );
        }
        expect(request.method, 'PUT');
        expect(request.url.path, '/api/Clientes/123456');
        expect(jsonDecode(request.body), {
          'nombres': 'Ana Original',
          'email': 'ana.nueva@example.com',
          'celular': '3001234567',
        });
        escrituras++;
        email = 'ana.nueva@example.com';
        return http.Response(
          '{"message":"Cliente actualizado correctamente"}',
          200,
        );
      });
      await tester.tap(find.byTooltip('Editar cliente'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Correo electrónico'),
        '  ana.nueva@example.com  ',
      );
      await _guardar(tester);

      expect(escrituras, 1);
      expect(lecturas, 2);
      expect(find.text('Editar cliente'), findsNothing);
      expect(find.textContaining('ana.nueva@example.com'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Guardar 204 desde listado recarga los datos sin excepciones', (
    tester,
  ) async {
    var lecturas = 0;
    var escrituras = 0;
    var nombre = 'Ana Original';
    await _montarLista(tester, (request) async {
      if (request.method == 'GET') {
        lecturas++;
        expect(request.url.path, '/api/Clientes');
        return http.Response(
          jsonEncode([
            {
              'identificacion': '123456',
              'nombres': nombre,
              'email': 'ana@example.com',
              'celular': '3001234567',
            },
          ]),
          200,
        );
      }
      expect(request.method, 'PUT');
      expect(request.url.path, '/api/Clientes/123456');
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body, {
        'nombres': 'Ana Actualizada',
        'email': 'ana@example.com',
        'celular': '3001234567',
      });
      escrituras++;
      nombre = body['nombres'] as String;
      return http.Response('', 204);
    });
    await _editarNombre(tester, 'Ana Actualizada');
    await _guardar(tester);

    expect(tester.takeException(), isNull);
    expect(escrituras, 1);
    expect(lecturas, 2);
    expect(find.text('Editar cliente'), findsNothing);
    expect(find.text('Ana Actualizada'), findsOneWidget);
    expect(find.text('Ana Original'), findsNothing);
  });

  testWidgets('Editar solo nombre con contactos null envía ambos null', (
    tester,
  ) async {
    var escrituras = 0;
    var nombre = 'Sin Contactos';
    await _montarLista(tester, (request) async {
      if (request.method == 'GET') {
        return http.Response(
          jsonEncode([
            {
              'identificacion': '654321',
              'nombres': nombre,
              'email': null,
              'celular': null,
            },
          ]),
          200,
        );
      }
      expect(request.method, 'PUT');
      expect(request.url.path, '/api/Clientes/654321');
      expect(jsonDecode(request.body), {
        'nombres': 'Nombre Actualizado',
        'email': null,
        'celular': null,
      });
      escrituras++;
      nombre = 'Nombre Actualizado';
      return http.Response('', 204);
    });
    await _editarNombre(tester, 'Nombre Actualizado');
    await _guardar(tester);

    expect(escrituras, 1);
    expect(find.text('Editar cliente'), findsNothing);
    expect(find.text('Nombre Actualizado'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Error 400 conserva formulario y permite reintentar guardado', (
    tester,
  ) async {
    var escrituras = 0;
    var lecturas = 0;
    var nombre = 'Ana Original';
    await _montarLista(tester, (request) async {
      if (request.method == 'GET') {
        lecturas++;
        return http.Response(
          jsonEncode([
            {
              'identificacion': '123456',
              'nombres': nombre,
              'email': 'ana@example.com',
              'celular': '3001234567',
            },
          ]),
          200,
        );
      }
      expect(request.method, 'PUT');
      expect(request.url.path, '/api/Clientes/123456');
      expect(jsonDecode(request.body), {
        'nombres': 'Ana Actualizada',
        'email': 'ana@example.com',
        'celular': '3001234567',
      });
      escrituras++;
      if (escrituras == 1) {
        return http.Response(
          jsonEncode({'message': 'No se pudo actualizar este cliente.'}),
          400,
        );
      }
      nombre = 'Ana Actualizada';
      return http.Response('', 204);
    });
    await _editarNombre(tester, 'Ana Actualizada');
    await _guardar(tester);

    expect(escrituras, 1);
    expect(lecturas, 1);
    expect(find.text('Editar cliente'), findsOneWidget);
    expect(find.text('No se pudo actualizar este cliente.'), findsOneWidget);
    final campoNombres = tester.widget<TextFormField>(
      find.widgetWithText(TextFormField, 'Nombres'),
    );
    expect(campoNombres.controller!.text, 'Ana Actualizada');
    expect(tester.takeException(), isNull);

    await _guardar(tester);
    expect(escrituras, 2);
    expect(lecturas, 2);
    expect(find.text('Editar cliente'), findsNothing);
    expect(find.text('Ana Actualizada'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

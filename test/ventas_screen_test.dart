import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smartbook_app/screens/ventas_screen.dart';
import 'package:smartbook_app/services/local/session_storage.dart';
import 'package:smartbook_app/services/remote/api_service.dart';
import 'package:smartbook_app/services/remote/venta_service.dart';

class _Storage implements SessionStorage {
  _Storage(this.token);
  final String? token;
  @override
  Future<String?> readToken() async => token;
  @override
  Future<void> saveToken(String token) async {}
  @override
  Future<void> clear() async {}
}

const _resumen = {
  'id': 103,
  'numeroRecibo': 'FAC-2026-000004',
  'numeroComprobante': '110438',
  'total': 1000000,
  'fecha': '2026-10-16T11:05:12.027847',
  'clienteNombre': 'Cliente de prueba',
};

VentaService _service(
  http.Response Function(http.Request) responder, {
  String? token = 'token',
}) {
  final client = MockClient((request) async => responder(request));
  addTearDown(client.close);
  return VentaService(
    api: ApiService(
      baseUrl: 'https://example.test/api',
      client: client,
      enableLogs: false,
    ),
    storage: _Storage(token),
  );
}

void main() {
  test('Listado GET autenticado convierte resúmenes sin items', () async {
    final service = _service((request) {
      expect(request.method, 'GET');
      expect(request.url.path, '/api/Ventas/');
      expect(request.url.queryParameters, isEmpty);
      expect(request.headers['authorization'], 'Bearer token');
      return http.Response(jsonEncode([_resumen]), 200);
    });
    final ventas = (await service.listarVentas()).data!;
    expect(ventas.single.id, 103);
    expect(ventas.single.numeroRecibo, 'FAC-2026-000004');
    expect(ventas.single.clienteNombre, 'Cliente de prueba');
    expect(ventas.single.total, 1000000);
    expect(ventas.single.fecha.day, 16);
  });

  test(
    'Listado envía el rango de fechas con los nombres de producción',
    () async {
      final service = _service((request) {
        expect(request.url.path, '/api/Ventas/');
        expect(request.url.queryParameters, {
          'desde': '2026-01-07',
          'hasta': '2026-10-30',
        });
        return http.Response(jsonEncode([_resumen]), 200);
      });
      final ventas = (await service.listarVentas(
        desde: DateTime(2026, 1, 7),
        hasta: DateTime(2026, 10, 30),
      )).data!;
      expect(ventas.single.numeroComprobante, '110438');
    },
  );

  test('Listado sin sesión no envía petición', () async {
    final service = _service(
      (_) => throw StateError('Must not request'),
      token: null,
    );
    await expectLater(service.listarVentas(), throwsA(isA<SessionException>()));
  });

  testWidgets('Muestra resumen y abre el detalle de la venta seleccionada', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var detalles = 0;
    final service = _service((request) {
      if (request.url.path == '/api/Ventas/') {
        return http.Response(jsonEncode([_resumen]), 200);
      }
      expect(request.url.path, '/api/ventas/103');
      detalles++;
      return http.Response(
        jsonEncode({..._resumen, 'numeroComprobante': '110438', 'items': []}),
        200,
      );
    });
    await tester.pumpWidget(MaterialApp(home: VentasScreen(service: service)));
    await tester.pumpAndSettle();
    expect(find.text('Cliente de prueba'), findsOneWidget);
    expect(find.text('Comprobante: 110438'), findsOneWidget);
    expect(find.text('Total: \$ 1.000.000,00'), findsOneWidget);
    expect(find.text('Fecha: 16/10/2026 11:05'), findsOneWidget);
    await tester.tap(find.text('FAC-2026-000004'));
    await tester.pumpAndSettle();
    expect(detalles, 1);
    expect(find.text('Venta #103'), findsOneWidget);
    expect(find.text('Cliente: Cliente de prueba'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Lista vacía permite actualizar', (tester) async {
    var llamadas = 0;
    final service = _service((_) {
      llamadas++;
      return http.Response('[]', 200);
    });
    await tester.pumpWidget(MaterialApp(home: VentasScreen(service: service)));
    await tester.pumpAndSettle();
    expect(find.text('No hay ventas para mostrar.'), findsOneWidget);
    await tester.tap(find.byTooltip('Actualizar ventas'));
    await tester.pumpAndSettle();
    expect(llamadas, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Error de servidor permite reintentar', (tester) async {
    var llamadas = 0;
    final service = _service((_) {
      llamadas++;
      return llamadas == 1
          ? http.Response('{"message":"Sales unavailable"}', 500)
          : http.Response(jsonEncode([_resumen]), 200);
    });
    await tester.pumpWidget(MaterialApp(home: VentasScreen(service: service)));
    await tester.pumpAndSettle();
    expect(find.text('Sales unavailable'), findsOneWidget);
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(find.text('FAC-2026-000004'), findsOneWidget);
    expect(llamadas, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Sesión vencida muestra mensaje sin ventas', (tester) async {
    final service = _service((_) => http.Response('{}', 401));
    await tester.pumpWidget(MaterialApp(home: VentasScreen(service: service)));
    await tester.pumpAndSettle();
    expect(
      find.text('Tu sesión ha expirado. Inicia sesión nuevamente.'),
      findsOneWidget,
    );
    expect(find.text('FAC-2026-000004'), findsNothing);
  });
}

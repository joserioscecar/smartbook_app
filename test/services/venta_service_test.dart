import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smartbook_app/screens/consultar_venta_screen.dart';
import 'package:smartbook_app/services/local/session_storage.dart';
import 'package:smartbook_app/services/remote/api_service.dart';
import 'package:smartbook_app/services/remote/venta_service.dart';

class _Storage implements SessionStorage {
  _Storage(this.token);
  final String? token;
  @override
  Future<String?> readToken() async => token;
  @override
  Future<void> clear() async {}
  @override
  Future<void> saveToken(String token) async {}
}

const _venta = {
  'id': 103,
  'numeroRecibo': 'FAC-2026-000004',
  'numeroComprobante': '110438',
  'total': 1000000.00,
  'fecha': '2026-10-16T11:05:12.027847',
  'clienteNombre': 'JOSE RIOS',
  'items': [
    {
      'libroId': 90,
      'nombreLibro': 'Superminds 1',
      'nivel': 'Kids A1.1',
      'lote': 20262,
      'cantidad': 10,
      'precioUnitario': 100000.00,
      'subtotal': 1000000.00,
    },
  ],
};

VentaService _service(
  http.Response Function(http.Request) responder, {
  String? token = 'token',
}) {
  final client = MockClient((request) async => responder(request));
  addTearDown(client.close);
  final api = ApiService(
    baseUrl: 'https://example.test/api',
    client: client,
    enableLogs: false,
  );
  return VentaService(api: api, storage: _Storage(token));
}

void main() {
  test('Consulta el endpoint con token y convierte todos los datos', () async {
    final service = _service((request) {
      expect(request.method, 'GET');
      expect(request.url.path, '/api/ventas/103');
      expect(request.headers['authorization'], 'Bearer token');
      return http.Response(jsonEncode(_venta), 200);
    });
    final response = await service.consultarVenta(103);
    final venta = response.data!;
    expect(venta.id, 103);
    expect(venta.numeroRecibo, 'FAC-2026-000004');
    expect(venta.numeroComprobante, '110438');
    expect(venta.clienteNombre, 'JOSE RIOS');
    expect(venta.total, 1000000);
    expect(venta.fecha, DateTime.parse(_venta['fecha'] as String));
    final item = venta.items.single;
    expect(item.libroId, 90);
    expect(item.nombreLibro, 'Superminds 1');
    expect(item.nivel, 'Kids A1.1');
    expect(item.lote, 20262);
    expect(item.cantidad, 10);
    expect(item.precioUnitario, 100000);
    expect(item.subtotal, 1000000);
  });

  test('Sin sesión o con ID inválido no envía solicitudes', () async {
    final service = _service(
      (_) => throw StateError('No debe enviar'),
      token: null,
    );
    await expectLater(
      service.consultarVenta(103),
      throwsA(isA<SessionException>()),
    );
    await expectLater(service.consultarVenta(0), throwsArgumentError);
  });

  testWidgets('Valida el ID y muestra el detalle de la venta', (tester) async {
    var solicitudes = 0;
    final service = _service((_) {
      solicitudes++;
      return http.Response(jsonEncode(_venta), 200);
    });
    await tester.pumpWidget(
      MaterialApp(home: ConsultarVentaScreen(service: service)),
    );
    await tester.tap(find.text('Consultar venta'));
    await tester.pump();
    expect(find.text('Ingresa un ID válido.'), findsOneWidget);
    expect(solicitudes, 0);
    await tester.enterText(find.byType(TextFormField), '103');
    await tester.tap(find.text('Consultar venta'));
    await tester.pumpAndSettle();
    expect(find.text('Venta #103'), findsOneWidget);
    expect(find.text('Cliente: JOSE RIOS'), findsOneWidget);
    expect(find.text('Total: \$ 1.000.000,00'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Superminds 1'),
      200,
      scrollable: find
          .byWidgetPredicate(
            (widget) =>
                widget is Scrollable &&
                widget.axisDirection == AxisDirection.down,
          )
          .first,
    );
    expect(find.text('Superminds 1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final status in [404, 401, 500]) {
    testWidgets('Muestra mensaje para respuesta $status', (tester) async {
      final service = _service((_) => http.Response('{}', status));
      await tester.pumpWidget(
        MaterialApp(home: ConsultarVentaScreen(service: service)),
      );
      await tester.enterText(find.byType(TextFormField), '103');
      await tester.tap(find.text('Consultar venta'));
      await tester.pumpAndSettle();
      expect(find.text('Venta #103'), findsNothing);
      expect(
        find.textContaining(
          status == 404
              ? 'No se encontró una venta'
              : status == 401
              ? 'Tu sesión ha expirado'
              : 'Server error (500)',
        ),
        findsOneWidget,
      );
    });
  }
}

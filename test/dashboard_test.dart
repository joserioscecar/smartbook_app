import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smartbook_app/services/local/session_storage.dart';
import 'package:smartbook_app/services/remote/api_service.dart';
import 'package:smartbook_app/services/remote/dashboard_service.dart';
import 'package:smartbook_app/widgets/dashboard_resumen.dart';

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

const _datos = {
  'totalLibros': 22,
  'totalClientes': 77,
  'cantVentasMes': 2,
  'totalVentasMes': 2000000.00,
  'ventasHoy': [
    {
      'numeroRecibo': 'FAC-2026-000005',
      'total': 1000000.00,
      'fecha': '2026-10-28T05:27:06.948822',
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
    },
  ],
};

DashboardService _service(
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
  return DashboardService(api: api, storage: _Storage(token));
}

void main() {
  test(
    'Consulta GET autenticado y convierte resumen y ventas sin ID',
    () async {
      final service = _service((request) {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/dashboard');
        expect(request.headers['authorization'], 'Bearer token');
        return http.Response(jsonEncode(_datos), 200);
      });
      final datos = (await service.consultarDashboard()).data!;
      expect(datos.totalLibros, 22);
      expect(datos.totalClientes, 77);
      expect(datos.cantVentasMes, 2);
      expect(datos.totalVentasMes, 2000000);
      final venta = datos.ventasHoy.single;
      expect(venta.numeroRecibo, 'FAC-2026-000005');
      expect(venta.total, 1000000);
      expect(venta.fecha.hour, 5);
      expect(venta.items.single.nombreLibro, 'Superminds 1');
      expect(venta.items.single.cantidad, 10);
    },
  );

  test('No consulta sin sesión', () async {
    final service = _service(
      (_) => throw StateError('No debe consultar'),
      token: null,
    );
    await expectLater(
      service.consultarDashboard(),
      throwsA(isA<SessionException>()),
    );
  });

  for (final ancho in [320.0, 520.0]) {
    testWidgets('Resumen y detalle de ventas a ancho $ancho', (tester) async {
      tester.view.physicalSize = Size(ancho, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final service = _service((_) => http.Response(jsonEncode(_datos), 200));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DashboardResumen(service: service, onUnauthorized: () {}),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('22'), findsOneWidget);
      expect(find.text('77'), findsOneWidget);
      expect(find.text('\$ 2.000.000,00'), findsOneWidget);
      await tester.tap(find.text('FAC-2026-000005'));
      await tester.pumpAndSettle();
      expect(find.text('Superminds 1'), findsOneWidget);
      expect(find.text('Cantidad: 10'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Permite reintentar y muestra ventas vacías', (tester) async {
    var llamadas = 0;
    final service = _service((_) {
      llamadas++;
      return llamadas == 1
          ? http.Response('{}', 500)
          : http.Response(jsonEncode({..._datos, 'ventasHoy': []}), 200);
    });
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: DashboardResumen(service: service, onUnauthorized: () {}),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reintentar dashboard'));
    await tester.pumpAndSettle();
    expect(llamadas, 2);
    await tester.scrollUntilVisible(
      find.text('No hay ventas registradas hoy.'),
      200,
    );
    expect(find.text('No hay ventas registradas hoy.'), findsOneWidget);
  });
}

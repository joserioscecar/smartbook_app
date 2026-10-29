import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartbook_app/main.dart';

void main() {
  testWidgets('No permite abrir el login con una sesión activa', (
    tester,
  ) async {
    await tester.pumpWidget(const SmartbookApp(logeado: true));
    await tester.pump();

    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.text('Filtrar por nombre'), findsNothing);
    expect(find.text('Iniciar sesión'), findsNothing);

    Navigator.of(tester.element(find.text('Dashboard'))).pushNamed('/login');
    await tester.pump();

    expect(find.text('Iniciar sesión'), findsNothing);
  });

  testWidgets('Valida campos de acceso', (tester) async {
    await tester.pumpWidget(const SmartbookApp());
    await tester.ensureVisible(find.text('Iniciar sesión'));
    await tester.tap(find.text('Iniciar sesión'));
    await tester.pumpAndSettle();
    expect(find.text('Ingresa un correo electrónico válido.'), findsOneWidget);
    expect(find.text('Ingresa tu contraseña.'), findsOneWidget);
    await tester.enterText(
      find.byType(TextFormField).first,
      'alumno@correo.com',
    );
    await tester.enterText(find.byType(TextFormField).last, 'clave');
    await tester.tap(find.byTooltip('Mostrar contraseña'));
    await tester.pump();
    expect(
      tester.widget<TextField>(find.byType(TextField).last).obscureText,
      isFalse,
    );
    await tester.ensureVisible(find.text('Iniciar sesión'));
    await tester.tap(find.text('Iniciar sesión'));
    await tester.pumpAndSettle();
    expect(find.textContaining('al conectar la API'), findsOneWidget);
  });
  for (final size in [const Size(320, 640), const Size(1440, 900)]) {
    testWidgets('Diseño adaptable a $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const SmartbookApp());
      await tester.pumpAndSettle();
      expect(find.text('Correo electrónico'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}

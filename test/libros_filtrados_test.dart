import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartbook_app/models/libro/libro_response.dart';
import 'package:smartbook_app/widgets/libros_filtrados.dart';

void main() {
  const libros = [
    LibroResponse(
      id: 1,
      nombre: 'Matemáticas',
      nivel: 'Primaria',
      tipo: 'Texto',
      stockTotal: 2,
    ),
    LibroResponse(
      id: 12,
      nombre: 'Lectura',
      nivel: 'Secundaria',
      tipo: 'Texto',
      stockTotal: 0,
    ),
    LibroResponse(id: 3, nombre: 'Ciencias', nivel: 'Primaria', tipo: 'Guía'),
  ];

  Future<void> montar(WidgetTester tester) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: LibrosFiltrados(
            libros: libros,
            itemBuilder: (libro) => Text('Libro: ${libro.nombre}'),
          ),
        ),
      ),
    ),
  );

  testWidgets('Busca por nombre sin distinguir acentos y no por ID', (
    tester,
  ) async {
    await montar(tester);
    await tester.enterText(find.byType(TextField), ' MATEMATICAS ');
    await tester.pump();
    expect(find.text('Libro: Matemáticas'), findsOneWidget);
    expect(find.text('Libro: Lectura'), findsNothing);
    await tester.enterText(find.byType(TextField), '1');
    await tester.pump();
    expect(find.text('0 de 3 libros'), findsOneWidget);
    expect(find.text('Libro: Matemáticas'), findsNothing);
    expect(find.text('Libro: Lectura'), findsNothing);
  });

  testWidgets('Combina nivel, tipo y stock y permite limpiar', (tester) async {
    await montar(tester);
    await tester.tap(find.byType(DropdownButton<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Primaria').last);
    await tester.pumpAndSettle();
    expect(find.text('2 de 3 libros'), findsOneWidget);
    await tester.tap(find.byType(DropdownButton<String>).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guía').last);
    await tester.pumpAndSettle();
    expect(find.text('Libro: Ciencias'), findsOneWidget);
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pump();
    expect(
      find.text('No hay libros que coincidan con los filtros.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Limpiar filtros'));
    await tester.pump();
    expect(find.text('3 de 3 libros'), findsOneWidget);
  });
}

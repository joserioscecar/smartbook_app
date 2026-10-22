import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../models/libros/libro.dart';
import '../routes/app_routes.dart';
import 'agregar_libro_screen.dart';

class InicioScreen extends StatefulWidget {
  const InicioScreen({super.key});

  @override
  State<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends State<InicioScreen> {
  final List<Libro> _books = [];

  void _navegarAgregarLibroScreen() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => AgregarLibroScreen(onBookCreated: _AgregarLibro),
      ),
    );
  }

  void _AgregarLibro(Libro book) {
    if (mounted) setState(() => _books.add(book));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('SmartBook'),
      titleTextStyle: const TextStyle(
        color: AppTheme.secondary,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
      actions: [
        IconButton(
          tooltip: 'Cerrar sesión',
          onPressed: () =>
              Navigator.of(context)
                  .pushNamedAndRemoveUntil(AppRoutes.login, (_) => false),
          icon: const Icon(Icons.logout_rounded),
        ),
      ],
    ),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const SizedBox(height: 28),
              const SizedBox(height: 28),
              const Text(
                '¡Bienvenido!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.secondary,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tu espacio de aprendizaje.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF77798B)),
              ),
              if (_books.isNotEmpty) ...[
                const SizedBox(height: 32),
                const Text(
                  'Mis libros',
                  style: TextStyle(
                    color: AppTheme.secondary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                for (final book in _books)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.menu_book_rounded,
                      color: AppTheme.primary,
                    ),
                    title: Text(book.nombre),
                    subtitle: Text('${book.nivel} · ${book.edicion}'),
                  ),
              ],
            ],
          ),
        ),
      ),
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _navegarAgregarLibroScreen,
      backgroundColor: AppTheme.primary,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.add_rounded),
      label: const Text('Crear libro'),
    ),
  );
}

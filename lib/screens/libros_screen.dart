import 'package:flutter/material.dart';
import 'package:smartbook_app/models/libro/libro_response.dart';

import '../config/app_theme.dart';
import '../routes/app_routes.dart';
import '../services/local/secure_storage_service.dart';
import '../services/local/user_preferences_service.dart';
import '../services/remote/api_service.dart';
import '../services/remote/libro_service.dart';
import '../widgets/libros_filtrados.dart';

class LibrosScreen extends StatefulWidget {
  const LibrosScreen({super.key, this.onLogout});

  final VoidCallback? onLogout;

  @override
  State<LibrosScreen> createState() => _LibrosScreenState();
}

class _LibrosScreenState extends State<LibrosScreen> {
  final _libroService = LibroService();
  late Future<ApiResponse<List<LibroResponse>>> _librosFuture;
  bool _cerrandoSesion = false;
  final Set<int> _librosEliminando = {};

  @override
  void initState() {
    super.initState();
    _librosFuture = _libroService.listarLibros();
  }

  void _recargarLibros() {
    setState(() {
      _librosFuture = _libroService.listarLibros();
    });
  }

  Future<void> _cerrarSesion() async {
    if (_cerrandoSesion) return;
    _cerrandoSesion = true;
    await _limpiarSesionYVolverAlLogin();
  }

  void _programarCierreSesion() {
    if (_cerrandoSesion) return;
    _cerrandoSesion = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _limpiarSesionYVolverAlLogin();
    });
  }

  Future<void> _limpiarSesionYVolverAlLogin() async {
    await SecureStorageService().clear();
    await UsuarioPreferencesService().eliminarUsuario();

    if (!mounted) return;
    widget.onLogout?.call();
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
  }

  Future<void> _navegarAgregarLibroScreen() async {
    await Navigator.of(context).pushNamed<bool>(AppRoutes.createBook);
    if (mounted) _recargarLibros();
  }

  Future<void> _eliminarLibro(LibroResponse libro) async {
    if (_librosEliminando.contains(libro.id)) return;
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar libro'),
        content: Text('¿Deseas eliminar "${libro.nombre}" (ID: ${libro.id})?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmado != true ||
        !mounted ||
        _librosEliminando.contains(libro.id)) {
      return;
    }
    setState(() => _librosEliminando.add(libro.id));
    try {
      final response = await _libroService.eliminarLibro(libro.id);
      if (!mounted) return;
      if (response.isUnauthorized) {
        _programarCierreSesion();
        return;
      }
      if (response.isSuccess) {
        _recargarLibros();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response.isSuccess
                ? 'Libro eliminado correctamente.'
                : response.message ?? 'No se pudo eliminar el libro.',
          ),
        ),
      );
    } on SessionException {
      if (mounted) _programarCierreSesion();
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _librosEliminando.remove(libro.id));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Libros'),
      titleTextStyle: const TextStyle(
        color: AppTheme.secondary,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
      actions: [
        IconButton(
          tooltip: 'Cerrar sesión',
          onPressed: _cerrarSesion,
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
              const Text(
                'Libros',
                style: TextStyle(
                  color: AppTheme.secondary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              FutureBuilder<ApiResponse<List<LibroResponse>>>(
                future: _librosFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (snapshot.hasError) {
                    final error = snapshot.error;
                    if (error is SessionException) {
                      _programarCierreSesion();
                    }
                    final message = error is ApiException
                        ? error.message
                        : error is SessionException
                        ? error.message
                        : 'No se pudieron cargar los libros.';
                    return Column(
                      children: [
                        Text(
                          message,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Color(0xFF77798B)),
                        ),
                        TextButton(
                          onPressed: _recargarLibros,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    );
                  }

                  final response = snapshot.data!;
                  if (response.isUnauthorized) {
                    _programarCierreSesion();
                  }
                  if (!response.isSuccess) {
                    return Column(
                      children: [
                        Text(
                          response.message ??
                              'Error HTTP ${response.statusCode}.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Color(0xFF77798B)),
                        ),
                        TextButton(
                          onPressed: _recargarLibros,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    );
                  }

                  final libros = response.data ?? const [];
                  if (libros.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        'No hay libros para mostrar.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xFF77798B)),
                      ),
                    );
                  }

                  return LibrosFiltrados(
                    libros: libros,
                    itemBuilder: _construirTarjetaLibro,
                  );
                },
              ),
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

  Widget _construirTarjetaLibro(LibroResponse libro) => Card(
    child: ListTile(
      leading: const Icon(Icons.menu_book_rounded, color: AppTheme.primary),
      title: Text(libro.nombre),
      trailing: _librosEliminando.contains(libro.id)
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : IconButton(
              tooltip: 'Eliminar libro',
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: () => _eliminarLibro(libro),
            ),
      subtitle: Text(
        'ID: ${libro.id}\n'
        'Nivel: ${libro.nivel}\n'
        'Stock: ${libro.stockTotal ?? 'No disponible'}',
      ),
      isThreeLine: true,
    ),
  );
}

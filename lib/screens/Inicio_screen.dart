import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../routes/app_routes.dart';
import '../services/local/secure_storage_service.dart';
import '../services/local/user_preferences_service.dart';
import '../widgets/dashboard_resumen.dart';

class InicioScreen extends StatefulWidget {
  const InicioScreen({super.key, this.onLogout});
  final VoidCallback? onLogout;
  @override
  State<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends State<InicioScreen> {
  bool _cerrandoSesion = false;
  int _dashboardRevision = 0;

  Future<void> _abrir(String ruta, {Object? arguments}) async {
    await Navigator.of(context).pushNamed(ruta, arguments: arguments);
    if (mounted) setState(() => _dashboardRevision++);
  }

  Future<void> _navegarAgregarLibroScreen() => _abrir(AppRoutes.createBook);

  Future<void> _cerrarSesion() async {
    if (_cerrandoSesion) return;
    _cerrandoSesion = true;
    await _limpiarSesionYVolverAlLogin();
  }

  void _programarCierreSesion() {
    if (_cerrandoSesion) return;
    _cerrandoSesion = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _limpiarSesionYVolverAlLogin();
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

  @override
  Widget build(BuildContext context) => Scaffold(
    drawer: Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: AppTheme.primary),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.menu_book_rounded, size: 48, color: Colors.white),
                  SizedBox(height: 12),
                  Text(
                    'SmartBook',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Tu espacio de aprendizaje.',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
            ListTile(
              selected: true,
              leading: const Icon(Icons.home_outlined),
              title: const Text('Dashboard'),
              onTap: () => Navigator.of(context).pop(),
            ),
            ListTile(
              leading: const Icon(Icons.menu_book_rounded),
              title: const Text('Libros'),
              onTap: () {
                Navigator.of(context).pop();
                _abrir(
                  AppRoutes.books,
                  arguments: LibrosRouteArgs(onLogout: widget.onLogout),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_rounded),
              title: const Text('Crear libro'),
              onTap: () {
                Navigator.of(context).pop();
                _navegarAgregarLibroScreen();
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.person_outline_rounded),
              title: const Text('Clientes'),
              onTap: () {
                Navigator.of(context).pop();
                _abrir(AppRoutes.clients);
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long_outlined),
              title: const Text('Ventas'),
              onTap: () {
                Navigator.of(context).pop();
                _abrir(AppRoutes.sales);
              },
            ),
            ListTile(
              leading: const Icon(Icons.search_rounded),
              title: const Text('Consultar venta por ID'),
              onTap: () {
                Navigator.of(context).pop();
                _abrir(AppRoutes.saleDetail);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout_rounded),
              title: const Text('Cerrar sesión'),
              onTap: () {
                Navigator.of(context).pop();
                _cerrarSesion();
              },
            ),
          ],
        ),
      ),
    ),
    appBar: AppBar(
      title: const Text('Dashboard'),
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
          constraints: const BoxConstraints(maxWidth: 900),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              DashboardResumen(
                revision: _dashboardRevision,
                onUnauthorized: _programarCierreSesion,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

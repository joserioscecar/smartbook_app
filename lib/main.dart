import 'package:flutter/material.dart';
import 'package:smartbook_app/services/local/user_preferences_service.dart';

import 'routes/app_routes.dart';
import 'screens/Inicio_screen.dart';
import 'screens/agregar_libro_screen.dart';
import 'screens/clientes_screen.dart';
import 'screens/consultar_venta_screen.dart';
import 'screens/crear_venta_screen.dart';
import 'screens/editar_cliente_screen.dart';
import 'screens/libros_screen.dart';
import 'screens/login_screen.dart';
import 'screens/restablecer_contrasena_screen.dart';
import 'screens/ventas_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final id = await UsuarioPreferencesService().obtenerId();
  final logeado = id != null && id.trim().isNotEmpty;

  runApp(SmartbookApp(logeado: logeado));
}

class SmartbookApp extends StatefulWidget {
  const SmartbookApp({super.key, this.logeado = false});

  final bool logeado;

  @override
  State<SmartbookApp> createState() => _SmartbookAppState();
}

class _SmartbookAppState extends State<SmartbookApp> {
  late bool _logeado = widget.logeado;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'SmartBook · CDI',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFE12D2E),
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: Colors.white,
    ),
    initialRoute: _logeado ? AppRoutes.home : AppRoutes.login,
    onGenerateRoute: (settings) {
      switch (settings.name) {
        case AppRoutes.login:
          return MaterialPageRoute(
            builder: (context) =>
                _logeado ? _inicioScreen() : const LoginScreen(),
          );
        case AppRoutes.home:
          return MaterialPageRoute(builder: (context) => _inicioScreen());
        case AppRoutes.resetPassword:
          return MaterialPageRoute(
            builder: (context) => const ResetPasswordScreen(),
          );
        case AppRoutes.books:
          final args = settings.arguments as LibrosRouteArgs?;
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => LibrosScreen(onLogout: args?.onLogout),
          );
        case AppRoutes.createBook:
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => const AgregarLibroScreen(),
          );
        case AppRoutes.clients:
          final args = settings.arguments as ClientesRouteArgs?;
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => ClientesScreen(service: args?.service),
          );
        case AppRoutes.editClient:
          final args = settings.arguments! as EditarClienteRouteArgs;
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => EditarClienteScreen(
              cliente: args.cliente,
              service: args.service,
            ),
          );
        case AppRoutes.sales:
          final args = settings.arguments as VentasRouteArgs?;
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => VentasScreen(service: args?.service),
          );
        case AppRoutes.createSale:
          final args = settings.arguments as CrearVentaRouteArgs?;
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => CrearVentaScreen(
              ventaService: args?.ventaService,
              clienteService: args?.clienteService,
              libroService: args?.libroService,
            ),
          );
        case AppRoutes.saleDetail:
          final args = settings.arguments as ConsultarVentaRouteArgs?;
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => ConsultarVentaScreen(
              ventaId: args?.ventaId,
              service: args?.service,
            ),
          );
        default:
          return MaterialPageRoute(
            builder: (context) =>
                _logeado ? _inicioScreen() : const LoginScreen(),
          );
      }
    },
  );

  InicioScreen _inicioScreen() =>
      InicioScreen(onLogout: () => setState(() => _logeado = false));
}

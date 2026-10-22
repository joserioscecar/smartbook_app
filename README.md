# SmartBook · CDI CECAR

Aplicación Flutter para Android e iOS con login en español, logo CDI y colores blanco, #e12d2e y #4142a1.

Ejecutar: `flutter pub get` y `flutter run` con un emulador o dispositivo Android conectado. iOS requiere macOS y Xcode.

## Estructura

- lib/main.dart: entrada de la aplicación.
- lib/config/: tema y configuración de API.
- lib/models/libros/: datos de libros y JSON.
- lib/models/seguridad/: solicitud de login y usuario.
- lib/routes/: navegación.
- lib/screens/: pantalla de login adaptable.
- lib/services/local/: token seguro y preferencias del usuario.
- lib/services/remote/: cliente HTTP para solicitudes JSON.
- assets/images/: logo original proporcionado.

## Integración pendiente

El cliente `ApiService` admite GET, POST, PUT y DELETE, con JSON, timeout y errores HTTP. Configura `API_BASE_URL` con `--dart-define=API_BASE_URL=https://tu-api`. `SecureStorageService` guarda el token en almacenamiento seguro y `UserPreferencesService` conserva id, nombre y correo localmente. El formulario de login todavía necesita el endpoint y el contrato de autenticación del servidor para completar el acceso.

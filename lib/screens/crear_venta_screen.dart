import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/cliente/cliente_response.dart';
import '../models/libro/libro_response.dart';
import '../models/venta/crear_venta_request.dart';
import '../services/remote/api_service.dart';
import '../services/remote/cliente_service.dart';
import '../services/remote/libro_service.dart';
import '../services/remote/venta_service.dart';

class CrearVentaScreen extends StatefulWidget {
  const CrearVentaScreen({
    super.key,
    this.ventaService,
    this.clienteService,
    this.libroService,
  });

  final VentaService? ventaService;
  final ClienteService? clienteService;
  final LibroService? libroService;

  @override
  State<CrearVentaScreen> createState() => _CrearVentaScreenState();
}

class _CrearVentaScreenState extends State<CrearVentaScreen> {
  late final _ventaService = widget.ventaService ?? VentaService();
  late final _clienteService = widget.clienteService ?? ClienteService();
  late final _libroService = widget.libroService ?? LibroService();
  late Future<_OpcionesVenta> _opciones;
  final _formKey = GlobalKey<FormState>();
  final _comprobanteController = TextEditingController();
  final _observacionesController = TextEditingController();
  final _cantidadController = TextEditingController(text: '1');
  final List<_ItemVentaBorrador> _items = [];
  String? _identificacionCliente;
  int? _libroId;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _opciones = _cargarOpciones();
  }

  Future<_OpcionesVenta> _cargarOpciones() async {
    final responses = await Future.wait<Object>([
      _clienteService.listarClientes(),
      _libroService.listarLibros(),
    ]);
    final clientesResponse = responses[0] as ApiResponse<List<ClienteResponse>>;
    final librosResponse = responses[1] as ApiResponse<List<LibroResponse>>;
    if (!clientesResponse.isSuccess) {
      throw ApiException(
        clientesResponse.message ?? 'Could not load customers.',
        statusCode: clientesResponse.statusCode,
      );
    }
    if (!librosResponse.isSuccess) {
      throw ApiException(
        librosResponse.message ?? 'Could not load books.',
        statusCode: librosResponse.statusCode,
      );
    }
    return _OpcionesVenta(
      clientes: clientesResponse.data ?? const [],
      libros: librosResponse.data ?? const [],
    );
  }

  void _agregarItem(List<LibroResponse> libros) {
    final libro = libros.where((item) => item.id == _libroId).firstOrNull;
    final cantidad = int.tryParse(_cantidadController.text.trim());
    if (libro == null) {
      _mostrarMensaje('Selecciona un libro.');
      return;
    }
    if (libro.lote == null) {
      _mostrarMensaje('El libro seleccionado no tiene un lote válido.');
      return;
    }
    if (cantidad == null || cantidad <= 0) {
      _mostrarMensaje('Ingresa una cantidad válida.');
      return;
    }
    final existente = _items
        .where((item) => item.libro.id == libro.id)
        .firstOrNull;
    if (existente != null) {
      existente.cantidad += cantidad;
    } else {
      _items.add(_ItemVentaBorrador(libro: libro, cantidad: cantidad));
    }
    _cantidadController.text = '1';
    setState(() {});
  }

  Future<void> _guardarVenta() async {
    if (_guardando || !_formKey.currentState!.validate()) return;
    if (_identificacionCliente == null) {
      _mostrarMensaje('Selecciona un cliente.');
      return;
    }
    if (_items.isEmpty) {
      _mostrarMensaje('Agrega al menos un libro a la venta.');
      return;
    }

    setState(() => _guardando = true);
    try {
      final response = await _ventaService.crearVenta(
        CrearVentaRequest(
          identificacionCliente: _identificacionCliente!,
          numeroComprobante: _comprobanteController.text.trim(),
          observaciones: _observacionesController.text.trim(),
          items: [
            for (final item in _items)
              CrearVentaItemRequest(
                libroId: item.libro.id,
                lote: item.libro.lote.toString(),
                cantidad: item.cantidad,
              ),
          ],
        ),
      );
      if (!mounted) return;
      if (!response.isSuccess) {
        _mostrarMensaje(
          response.isUnauthorized
              ? 'Your session has expired. Sign in again.'
              : response.message ?? 'Could not create the sale.',
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Venta realizada correctamente.')),
      );
      Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      _mostrarMensaje(error.message);
    } on SessionException catch (error) {
      _mostrarMensaje(error.message);
    } catch (_) {
      _mostrarMensaje('Could not create the sale.');
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensaje)));
  }

  @override
  void dispose() {
    _comprobanteController.dispose();
    _observacionesController.dispose();
    _cantidadController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Realizar venta')),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: FutureBuilder<_OpcionesVenta>(
            future: _opciones,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return _estadoError(snapshot.error);
              }
              final opciones = snapshot.data!;
              return _formulario(opciones);
            },
          ),
        ),
      ),
    ),
  );

  Widget _estadoError(Object? error) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            error is ApiException || error is SessionException
                ? error.toString()
                : 'Could not load customers and books.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => setState(() => _opciones = _cargarOpciones()),
            child: const Text('Retry'),
          ),
        ],
      ),
    ),
  );

  Widget _formulario(_OpcionesVenta opciones) {
    final clientes = opciones.clientes;
    final libros = opciones.libros;
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          DropdownButtonFormField<String>(
            initialValue: _identificacionCliente,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Cliente'),
            items: [
              for (final cliente in clientes)
                DropdownMenuItem(
                  value: cliente.identificacion,
                  child: Text(
                    '${cliente.nombres} · ${cliente.identificacion}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: _guardando
                ? null
                : (value) => setState(() => _identificacionCliente = value),
            validator: (value) =>
                value == null ? 'Selecciona un cliente.' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _comprobanteController,
            decoration: const InputDecoration(
              labelText: 'Número de comprobante',
            ),
            textInputAction: TextInputAction.next,
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Ingresa el número de comprobante.'
                : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _observacionesController,
            decoration: const InputDecoration(labelText: 'Observaciones'),
            minLines: 2,
            maxLines: 4,
          ),
          const SizedBox(height: 24),
          Text('Libros', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: DropdownButtonFormField<int>(
                  initialValue: _libroId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Libro'),
                  items: [
                    for (final libro in libros)
                      DropdownMenuItem(
                        value: libro.id,
                        child: Text(
                          '${libro.nombre} · Lote ${libro.lote ?? 'N/D'}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: _guardando
                      ? null
                      : (value) => setState(() => _libroId = value),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _cantidadController,
                  enabled: !_guardando,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(labelText: 'Cantidad'),
                ),
              ),
              IconButton(
                tooltip: 'Agregar libro',
                onPressed: _guardando ? null : () => _agregarItem(libros),
                icon: const Icon(Icons.add_circle_outline_rounded),
              ),
            ],
          ),
          if (_items.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (final item in _items)
              Card(
                child: ListTile(
                  title: Text(item.libro.nombre),
                  subtitle: Text(
                    'Lote ${item.libro.lote} · ${item.cantidad} unidades',
                  ),
                  trailing: IconButton(
                    tooltip: 'Quitar ${item.libro.nombre}',
                    onPressed: _guardando
                        ? null
                        : () => setState(() => _items.remove(item)),
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
                ),
              ),
          ],
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _guardando ? null : _guardarVenta,
            icon: _guardando
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.point_of_sale_rounded),
            label: Text(_guardando ? 'Guardando…' : 'Realizar venta'),
          ),
        ],
      ),
    );
  }
}

class _OpcionesVenta {
  const _OpcionesVenta({required this.clientes, required this.libros});

  final List<ClienteResponse> clientes;
  final List<LibroResponse> libros;
}

class _ItemVentaBorrador {
  _ItemVentaBorrador({required this.libro, required this.cantidad});

  final LibroResponse libro;
  int cantidad;
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/venta/venta_response.dart';
import '../services/remote/api_service.dart';
import '../services/remote/venta_service.dart';

class ConsultarVentaScreen extends StatefulWidget {
  const ConsultarVentaScreen({super.key, this.service, this.ventaId});

  final VentaService? service;
  final int? ventaId;

  @override
  State<ConsultarVentaScreen> createState() => _ConsultarVentaScreenState();
}

class _ConsultarVentaScreenState extends State<ConsultarVentaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  late final _service = widget.service ?? VentaService();
  VentaResponse? _venta;
  String? _mensaje;
  bool _consultando = false;

  @override
  void initState() {
    super.initState();
    final id = widget.ventaId;
    if (id != null) {
      _idController.text = '$id';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _consultar();
      });
    }
  }

  @override
  void dispose() {
    _idController.dispose();
    super.dispose();
  }

  Future<void> _consultar() async {
    if (_consultando || !(_formKey.currentState?.validate() ?? false)) return;
    final id = int.parse(_idController.text.trim());
    FocusScope.of(context).unfocus();
    setState(() {
      _consultando = true;
      _venta = null;
      _mensaje = null;
    });
    try {
      final response = await _service.consultarVenta(id);
      if (!mounted) return;
      setState(() {
        if (response.isNotFound) {
          _mensaje = 'No se encontró una venta con el ID $id.';
        } else if (response.isUnauthorized) {
          _mensaje = 'Tu sesión ha expirado. Inicia sesión nuevamente.';
        } else if (!response.isSuccess) {
          _mensaje = response.message ?? 'No se pudo consultar la venta.';
        } else if (response.data == null) {
          _mensaje = 'La respuesta no contiene información de la venta.';
        } else {
          _venta = response.data;
        }
      });
    } on ApiException catch (error) {
      if (mounted) setState(() => _mensaje = error.message);
    } on SessionException catch (error) {
      if (mounted) setState(() => _mensaje = error.message);
    } finally {
      if (mounted) setState(() => _consultando = false);
    }
  }

  String _importe(num valor) {
    final partes = valor.toStringAsFixed(2).split('.');
    final entero = partes.first.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );
    return '\$ $entero,${partes.last}';
  }

  String _fecha(DateTime fecha) {
    String dos(int valor) => valor.toString().padLeft(2, '0');
    return '${dos(fecha.day)}/${dos(fecha.month)}/${fecha.year} '
        '${dos(fecha.hour)}:${dos(fecha.minute)}:${dos(fecha.second)}';
  }

  Widget _detalle(String etiqueta, String valor) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Text('$etiqueta: $valor'),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Consultar venta por ID')),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text(
                'Ingresa el ID de la venta para consultar sus detalles.',
              ),
              const SizedBox(height: 20),
              Form(
                key: _formKey,
                child: TextFormField(
                  controller: _idController,
                  enabled: !_consultando,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.search,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onFieldSubmitted: (_) => _consultar(),
                  validator: (valor) {
                    final id = int.tryParse(valor?.trim() ?? '');
                    return id == null || id <= 0
                        ? 'Ingresa un ID válido.'
                        : null;
                  },
                  decoration: const InputDecoration(
                    labelText: 'ID de la venta',
                    hintText: 'Ej. 103',
                    prefixIcon: Icon(Icons.receipt_long_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _consultando ? null : _consultar,
                icon: _consultando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.search_rounded),
                label: Text(
                  _consultando ? 'Consultando...' : 'Consultar venta',
                ),
              ),
              if (_mensaje != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(_mensaje!, textAlign: TextAlign.center),
                ),
              if (_venta case final venta?) ...[
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Venta #${venta.id}',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const Divider(),
                        _detalle('Recibo', venta.numeroRecibo),
                        _detalle('Comprobante', venta.numeroComprobante),
                        _detalle('Cliente', venta.clienteNombre),
                        _detalle('Fecha', _fecha(venta.fecha)),
                        _detalle('Total', _importe(venta.total)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Libros vendidos (${venta.items.length})',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (venta.items.isEmpty)
                  const Text('Esta venta no contiene libros.'),
                for (final item in venta.items)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.nombreLibro,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          _detalle('ID del libro', '${item.libroId}'),
                          _detalle('Nivel', item.nivel),
                          _detalle('Lote', '${item.lote}'),
                          _detalle('Cantidad', '${item.cantidad}'),
                          _detalle(
                            'Precio unitario',
                            _importe(item.precioUnitario),
                          ),
                          _detalle('Subtotal', _importe(item.subtotal)),
                        ],
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}

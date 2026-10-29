import 'package:flutter/material.dart';

import '../models/venta/venta_resumen_response.dart';
import '../routes/app_routes.dart';
import '../services/remote/api_service.dart';
import '../services/remote/venta_service.dart';

class VentasScreen extends StatefulWidget {
  const VentasScreen({super.key, this.service});

  final VentaService? service;

  @override
  State<VentasScreen> createState() => _VentasScreenState();
}

class _VentasScreenState extends State<VentasScreen> {
  late final _service = widget.service ?? VentaService();
  late Future<ApiResponse<List<VentaResumenResponse>>> _ventas;
  DateTimeRange? _rangoFechas;

  @override
  void initState() {
    super.initState();
    _ventas = _service.listarVentas();
  }

  void _recargar() {
    setState(() {
      _ventas = _service.listarVentas(
        desde: _rangoFechas?.start,
        hasta: _rangoFechas?.end,
      );
    });
  }

  Future<void> _filtrarFechas() async {
    final ahora = DateTime.now();
    final rango = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(ahora.year, ahora.month, ahora.day),
      initialDateRange: _rangoFechas,
      helpText: 'Selecciona el rango de ventas',
      cancelText: 'Cancelar',
      confirmText: 'Aplicar',
      saveText: 'Aplicar',
      fieldStartHintText: 'Fecha inicial',
      fieldEndHintText: 'Fecha final',
    );
    if (rango == null || !mounted) return;
    setState(() => _rangoFechas = rango);
    _recargar();
  }

  void _limpiarFiltro() {
    setState(() => _rangoFechas = null);
    _recargar();
  }

  Future<void> _nuevaVenta() async {
    final creada = await Navigator.of(context).pushNamed<bool>(
      AppRoutes.createSale,
      arguments: CrearVentaRouteArgs(ventaService: _service),
    );
    if (creada == true && mounted) _recargar();
  }

  Future<void> _actualizar() async {
    _recargar();
    try {
      await _ventas;
    } catch (_) {
      // FutureBuilder muestra el error y permite reintentar.
    }
  }

  Widget _mensaje(String mensaje) => ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    padding: const EdgeInsets.all(24),
    children: [
      Text(mensaje, textAlign: TextAlign.center),
      TextButton(onPressed: _recargar, child: const Text('Reintentar')),
    ],
  );

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
        '${dos(fecha.hour)}:${dos(fecha.minute)}';
  }

  String _soloFecha(DateTime fecha) =>
      '${fecha.day.toString().padLeft(2, '0')}/'
      '${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Ventas'),
      actions: [
        IconButton(
          tooltip: 'Filtrar por fechas',
          onPressed: _filtrarFechas,
          icon: const Icon(Icons.date_range_rounded),
        ),
        if (_rangoFechas != null)
          IconButton(
            tooltip: 'Quitar filtro de fechas',
            onPressed: _limpiarFiltro,
            icon: const Icon(Icons.filter_alt_off_rounded),
          ),
        IconButton(
          tooltip: 'Actualizar ventas',
          onPressed: _recargar,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _nuevaVenta,
      icon: const Icon(Icons.add_rounded),
      label: const Text('Realizar venta'),
    ),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: RefreshIndicator(
            onRefresh: _actualizar,
            child: FutureBuilder<ApiResponse<List<VentaResumenResponse>>>(
              future: _ventas,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  final error = snapshot.error;
                  return _mensaje(
                    error is ApiException
                        ? error.message
                        : error is SessionException
                        ? error.message
                        : 'No se pudieron cargar las ventas.',
                  );
                }
                final response = snapshot.data!;
                if (!response.isSuccess) {
                  return _mensaje(
                    response.isUnauthorized
                        ? 'Tu sesión ha expirado. Inicia sesión nuevamente.'
                        : response.message ??
                              'No se pudieron cargar las ventas.',
                  );
                }
                final ventas = response.data ?? const <VentaResumenResponse>[];
                if (ventas.isEmpty) {
                  return _mensaje('No hay ventas para mostrar.');
                }
                return ListView(
                  padding: const EdgeInsets.all(16),
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    if (_rangoFechas != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'Periodo: ${_soloFecha(_rangoFechas!.start)} – '
                          '${_soloFecha(_rangoFechas!.end)}',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    for (final venta in ventas)
                      Card(
                        child: ListTile(
                          title: Text(venta.numeroRecibo),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(venta.clienteNombre),
                                if (venta.numeroComprobante.isNotEmpty)
                                  Text(
                                    'Comprobante: ${venta.numeroComprobante}',
                                  ),
                                Text('Fecha: ${_fecha(venta.fecha)}'),
                                Text('Total: ${_importe(venta.total)}'),
                              ],
                            ),
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => Navigator.of(context).pushNamed<void>(
                            AppRoutes.saleDetail,
                            arguments: ConsultarVentaRouteArgs(
                              ventaId: venta.id,
                              service: _service,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    ),
  );
}

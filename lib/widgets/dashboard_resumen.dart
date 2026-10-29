import 'package:flutter/material.dart';

import '../models/dashboard/dashboard_response.dart';
import '../services/remote/api_service.dart';
import '../services/remote/dashboard_service.dart';

class DashboardResumen extends StatefulWidget {
  const DashboardResumen({
    super.key,
    required this.onUnauthorized,
    this.revision = 0,
    this.service,
  });

  final VoidCallback onUnauthorized;
  final int revision;
  final DashboardService? service;

  @override
  State<DashboardResumen> createState() => _DashboardResumenState();
}

class _DashboardResumenState extends State<DashboardResumen> {
  late final _service = widget.service ?? DashboardService();
  late Future<ApiResponse<DashboardResponse>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.consultarDashboard();
  }

  @override
  void didUpdateWidget(covariant DashboardResumen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.revision != widget.revision) {
      _future = _service.consultarDashboard();
    }
  }

  void _recargar() => setState(() {
    _future = _service.consultarDashboard();
  });

  String _importe(num valor) {
    final partes = valor.toStringAsFixed(2).split('.');
    final entero = partes.first.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );
    return '\$ $entero,${partes.last}';
  }

  Widget _error(String mensaje) => Column(
    children: [
      Text(mensaje, textAlign: TextAlign.center),
      TextButton(
        onPressed: _recargar,
        child: const Text('Reintentar dashboard'),
      ),
    ],
  );

  Widget _indicador(String etiqueta, String valor, IconData icono) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 8),
          Text(valor, style: Theme.of(context).textTheme.titleLarge),
          Text(etiqueta),
        ],
      ),
    ),
  );

  @override
  Widget build(
    BuildContext context,
  ) => FutureBuilder<ApiResponse<DashboardResponse>>(
    future: _future,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        );
      }
      if (snapshot.hasError) {
        final error = snapshot.error;
        if (error is SessionException) widget.onUnauthorized();
        return _error(
          error is ApiException
              ? error.message
              : error is SessionException
              ? error.message
              : 'No se pudo cargar el dashboard.',
        );
      }
      final response = snapshot.data!;
      if (response.isUnauthorized) widget.onUnauthorized();
      if (!response.isSuccess) {
        return _error(response.message ?? 'No se pudo cargar el dashboard.');
      }
      final dashboard = response.data;
      if (dashboard == null) {
        return _error('La respuesta no contiene datos del dashboard.');
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Resumen',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton(
                tooltip: 'Actualizar dashboard',
                onPressed: _recargar,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final ancho = constraints.maxWidth < 360
                  ? constraints.maxWidth
                  : (constraints.maxWidth - 12) / 2;
              return Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  SizedBox(
                    width: ancho,
                    child: _indicador(
                      'Total libros',
                      '${dashboard.totalLibros}',
                      Icons.menu_book_rounded,
                    ),
                  ),
                  SizedBox(
                    width: ancho,
                    child: _indicador(
                      'Total clientes',
                      '${dashboard.totalClientes}',
                      Icons.people_outline,
                    ),
                  ),
                  SizedBox(
                    width: ancho,
                    child: _indicador(
                      'Ventas del mes',
                      '${dashboard.cantVentasMes}',
                      Icons.receipt_long_outlined,
                    ),
                  ),
                  SizedBox(
                    width: ancho,
                    child: _indicador(
                      'Total vendido del mes',
                      _importe(dashboard.totalVentasMes),
                      Icons.payments_outlined,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          Text('Ventas de hoy', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          if (dashboard.ventasHoy.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('No hay ventas registradas hoy.'),
            ),
          for (final venta in dashboard.ventasHoy)
            Card(
              child: ExpansionTile(
                title: Text(venta.numeroRecibo),
                subtitle: Text(
                  '${_importe(venta.total)} · '
                  '${venta.fecha.hour.toString().padLeft(2, '0')}:'
                  '${venta.fecha.minute.toString().padLeft(2, '0')}',
                ),
                childrenPadding: const EdgeInsets.all(16),
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (venta.items.isEmpty)
                    const Text('Esta venta no contiene libros.'),
                  for (final item in venta.items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.nombreLibro,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            'ID: ${item.libroId} · Nivel: ${item.nivel} · Lote: ${item.lote}',
                          ),
                          Text('Cantidad: ${item.cantidad}'),
                          Text(
                            'Precio unitario: ${_importe(item.precioUnitario)}',
                          ),
                          Text('Subtotal: ${_importe(item.subtotal)}'),
                        ],
                      ),
                    ),
                ],
              ),
            ),
        ],
      );
    },
  );
}

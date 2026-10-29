import 'package:flutter/material.dart';

import '../models/cliente/cliente_response.dart';
import '../routes/app_routes.dart';
import '../services/remote/api_service.dart';
import '../services/remote/cliente_service.dart';

class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key, this.service});

  final ClienteService? service;

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  late final _service = widget.service ?? ClienteService();
  late Future<ApiResponse<List<ClienteResponse>>> _clientes;

  @override
  void initState() {
    super.initState();
    _clientes = _service.listarClientes();
  }

  void _recargar() {
    setState(() {
      _clientes = _service.listarClientes();
    });
  }

  Future<void> _editar(ClienteResponse cliente) async {
    final actualizado = await Navigator.of(context).pushNamed<bool>(
      AppRoutes.editClient,
      arguments: EditarClienteRouteArgs(cliente: cliente, service: _service),
    );
    if (actualizado == true && mounted) _recargar();
  }

  Widget _mensaje(String mensaje) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(mensaje, textAlign: TextAlign.center),
          TextButton(onPressed: _recargar, child: const Text('Reintentar')),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Clientes'),
      actions: [
        IconButton(
          tooltip: 'Actualizar clientes',
          onPressed: _recargar,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
    ),
    body: SafeArea(
      child: FutureBuilder<ApiResponse<List<ClienteResponse>>>(
        future: _clientes,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            final error = snapshot.error;
            return _mensaje(
              error is SessionException
                  ? error.message
                  : error is ApiException
                  ? error.message
                  : 'No se pudieron cargar los clientes.',
            );
          }
          final response = snapshot.data!;
          if (!response.isSuccess) {
            return _mensaje(
              response.isUnauthorized
                  ? 'Tu sesión ha expirado. Inicia sesión nuevamente.'
                  : response.message ?? 'No se pudieron cargar los clientes.',
            );
          }
          final clientes = response.data ?? const <ClienteResponse>[];
          if (clientes.isEmpty) {
            return _mensaje('No hay clientes para mostrar.');
          }
          return RefreshIndicator(
            onRefresh: () async {
              _recargar();
              await _clientes;
            },
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: clientes.length,
              itemBuilder: (context, index) {
                final cliente = clientes[index];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.person_outline_rounded),
                    title: Text(cliente.nombres),
                    subtitle: Text(
                      'Identificación: ${cliente.identificacion}\n'
                      '${cliente.email}\n${cliente.celular}',
                    ),
                    isThreeLine: true,
                    trailing: IconButton(
                      tooltip: 'Editar cliente',
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => _editar(cliente),
                    ),
                    onTap: () => _editar(cliente),
                  ),
                );
              },
            ),
          );
        },
      ),
    ),
  );
}

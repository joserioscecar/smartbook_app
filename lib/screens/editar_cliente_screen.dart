import 'package:flutter/material.dart';

import '../models/cliente/editar_cliente_request.dart';
import '../models/cliente/cliente_response.dart';
import '../services/remote/api_service.dart';
import '../services/remote/cliente_service.dart';

class EditarClienteScreen extends StatefulWidget {
  const EditarClienteScreen({super.key, this.cliente, this.service});

  final ClienteResponse? cliente;
  final ClienteService? service;

  @override
  State<EditarClienteScreen> createState() => _EditarClienteScreenState();
}

class _EditarClienteScreenState extends State<EditarClienteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identificacion = TextEditingController();
  final _nombres = TextEditingController();
  final _email = TextEditingController();
  final _celular = TextEditingController();
  late final _service = widget.service ?? ClienteService();
  bool _guardando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final cliente = widget.cliente;
    if (cliente != null) {
      _identificacion.text = cliente.identificacion;
      _nombres.text = cliente.nombres;
      _email.text = cliente.email;
      _celular.text = cliente.celular;
    }
  }

  @override
  void dispose() {
    for (final controller in [_identificacion, _nombres, _email, _celular]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _guardar() async {
    if (_guardando || !(_formKey.currentState?.validate() ?? false)) return;
    final email = _email.text.trim();
    final celular = _celular.text.trim();
    FocusScope.of(context).unfocus();
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      final response = await _service.editarCliente(
        _identificacion.text.trim(),
        EditarClienteRequest(
          nombres: _nombres.text.trim(),
          email: email.isEmpty ? null : email,
          celular: celular.isEmpty ? null : celular,
        ),
      );
      if (!mounted) return;
      if (response.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cliente actualizado correctamente.')),
        );
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _error = response.isNotFound
              ? 'No se encontró un cliente con esa identificación.'
              : response.isUnauthorized
              ? 'Tu sesión ha expirado. Inicia sesión nuevamente.'
              : response.message ?? 'No se pudo actualizar el cliente.';
        });
      }
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } on SessionException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  String? _requerido(String? value) => value == null || value.trim().isEmpty
      ? 'Este campo es obligatorio.'
      : null;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Editar cliente')),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const Text(
                  'Actualiza los datos del cliente. El correo y el celular son opcionales.',
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _identificacion,
                  readOnly: widget.cliente != null,
                  enabled: !_guardando,
                  decoration: const InputDecoration(
                    labelText: 'Identificación',
                  ),
                  textInputAction: TextInputAction.next,
                  validator: _requerido,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nombres,
                  enabled: !_guardando,
                  decoration: const InputDecoration(labelText: 'Nombres'),
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  validator: _requerido,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _email,
                  enabled: !_guardando,
                  decoration: const InputDecoration(
                    labelText: 'Correo electrónico',
                    helperText: 'Opcional',
                  ),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                  validator: (value) {
                    final email = value?.trim() ?? '';
                    if (email.isEmpty) return null;
                    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)
                        ? null
                        : 'Ingresa un correo válido.';
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _celular,
                  enabled: !_guardando,
                  decoration: const InputDecoration(
                    labelText: 'Celular',
                    helperText: 'Opcional',
                  ),
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _guardar(),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 20),
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _guardando ? null : _guardar,
                  icon: _guardando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(_guardando ? 'Guardando...' : 'Guardar cambios'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../models/libro/libro_request.dart';
import '../services/remote/api_service.dart';
import '../services/remote/libro_service.dart';
import '../widgets/buttons/primary_button.dart';
import '../widgets/fields/book_number_field.dart';
import '../widgets/fields/custom_text_field.dart';

class AgregarLibroScreen extends StatefulWidget {
  const AgregarLibroScreen({super.key});

  @override
  State<AgregarLibroScreen> createState() => _AgregarLibroScreenState();
}

class _AgregarLibroScreenState extends State<AgregarLibroScreen> {
  final _formKey = GlobalKey<FormState>();
  final _libroService = LibroService();
  final _nombreController = TextEditingController();
  final _nivelController = TextEditingController();
  final _unidadesController = TextEditingController();
  final _valorCompraController = TextEditingController();
  final _valorVentaPublicoController = TextEditingController();
  final _loteController = TextEditingController();
  int? _tipoSeleccionado;
  bool _guardando = false;

  @override
  void dispose() {
    for (final controller in [
      _nombreController,
      _nivelController,
      _unidadesController,
      _valorCompraController,
      _valorVentaPublicoController,
      _loteController,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _validarRequerido(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Este campo es obligatorio.';
    }
    return null;
  }

  String? _validarNumero(String? value) {
    if (_validarRequerido(value) != null) return 'Este campo es obligatorio.';
    if (int.tryParse(value!.trim()) == null) return 'Ingresa un número válido.';
    return null;
  }

  void _limpiarFormulario() {
    for (final controller in [
      _nombreController,
      _nivelController,
      _unidadesController,
      _valorCompraController,
      _valorVentaPublicoController,
      _loteController,
    ]) {
      controller.clear();
    }
    _formKey.currentState?.reset();
    setState(() => _tipoSeleccionado = null);
  }

  Future<void> _guardarLibro() async {
    if (_guardando || !(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _guardando = true);
    try {
      final response = await _libroService.crearLibro(
        CrearLibroRequest(
          nombre: _nombreController.text.trim(),
          nivel: _nivelController.text.trim(),
          tipo: _tipoSeleccionado!,
          unidades: int.parse(_unidadesController.text.trim()),
          lote: int.parse(_loteController.text.trim()),
          valorCompra: int.parse(_valorCompraController.text.trim()),
          valorVentaPublico: int.parse(
            _valorVentaPublicoController.text.trim(),
          ),
        ),
      );

      if (!mounted) return;
      if (!response.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response.message ?? 'Error HTTP ${response.statusCode}.',
            ),
          ),
        );
        return;
      }

      _limpiarFormulario();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Libro creado correctamente.')),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } on SessionException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Crear libro')),
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  const Text(
                    'Crear libro',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.secondary,
                      fontSize: 25,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 24),
                  CustomTextField(
                    controller: _nombreController,
                    label: 'Nombre',
                    textInputAction: TextInputAction.next,
                    validator: _validarRequerido,
                  ),
                  const SizedBox(height: 14),
                  CustomTextField(
                    controller: _nivelController,
                    label: 'Nivel',
                    hintText: 'Ej. Teens A2.1',
                    textInputAction: TextInputAction.next,
                    validator: _validarRequerido,
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<int>(
                    initialValue: _tipoSeleccionado,
                    decoration: InputDecoration(
                      labelText: 'Tipo',
                      filled: true,
                      fillColor: const Color(0xFFF7F8FC),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 18,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EF)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EF)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: AppTheme.primary,
                          width: 1.5,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppTheme.primary),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: AppTheme.primary,
                          width: 1.5,
                        ),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 1, child: Text("Student's Book")),
                      DropdownMenuItem(value: 2, child: Text('Workbook')),
                    ],
                    onChanged: (value) =>
                        setState(() => _tipoSeleccionado = value),
                    validator: (value) =>
                        value == null ? 'Selecciona el tipo de libro.' : null,
                  ),
                  const SizedBox(height: 14),
                  BookNumberField(
                    controller: _unidadesController,
                    label: 'Unidades',
                    validator: _validarNumero,
                  ),
                  const SizedBox(height: 14),
                  BookNumberField(
                    controller: _valorCompraController,
                    label: 'Valor de compra',
                    validator: _validarNumero,
                  ),
                  const SizedBox(height: 14),
                  BookNumberField(
                    controller: _valorVentaPublicoController,
                    label: 'Valor venta público',
                    validator: _validarNumero,
                  ),
                  const SizedBox(height: 14),
                  BookNumberField(
                    controller: _loteController,
                    label: 'Lote',
                    validator: _validarNumero,
                  ),
                  const SizedBox(height: 22),
                  PrimaryButton(
                    label: 'Guardar libro',
                    onPressed: _guardarLibro,
                    isLoading: _guardando,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

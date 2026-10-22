import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../controllers/book_form_controller.dart';
import '../models/libros/libro.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/book_number_field.dart';
import '../widgets/primary_button.dart';

class AgregarLibroScreen extends StatefulWidget {
  const AgregarLibroScreen({required this.onBookCreated, super.key});

  final ValueChanged<Libro> onBookCreated;

  @override
  State<AgregarLibroScreen> createState() => _AgregarLibroScreenState();
}

class _AgregarLibroScreenState extends State<AgregarLibroScreen> {
  final _controller = BookFormController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
                  controller: _controller.nombre,
                  label: 'Nombre',
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 14),
                CustomTextField(
                  controller: _controller.nivel,
                  label: 'Nivel',
                  hintText: 'Ej. Teens A2.1',
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 14),
                BookNumberField(controller: _controller.tipo, label: 'Tipo'),
                const SizedBox(height: 14),
                CustomTextField(
                  controller: _controller.edicion,
                  label: 'Edición',
                  hintText: 'Ej. 1ra',
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 14),
                BookNumberField(
                  controller: _controller.unidades,
                  label: 'Unidades',
                ),
                const SizedBox(height: 14),
                BookNumberField(
                  controller: _controller.valorCompra,
                  label: 'Valor de compra',
                ),
                const SizedBox(height: 14),
                BookNumberField(
                  controller: _controller.valorVentaPublico,
                  label: 'Valor venta público',
                ),
                const SizedBox(height: 14),
                CustomTextField(
                  controller: _controller.lote,
                  label: 'Lote',
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _controller.save(
                    onBookCreated: widget.onBookCreated,
                    onClose: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(height: 22),
                PrimaryButton(
                  label: 'Guardar libro',
                  onPressed: () => _controller.save(
                    onBookCreated: widget.onBookCreated,
                    onClose: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

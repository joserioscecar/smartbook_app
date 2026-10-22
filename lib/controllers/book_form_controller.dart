import 'package:flutter/material.dart';

import '../models/libros/libro.dart';

class BookFormController {
  final nombre = TextEditingController();
  final nivel = TextEditingController();
  final tipo = TextEditingController();
  final edicion = TextEditingController();
  final unidades = TextEditingController();
  final valorCompra = TextEditingController();
  final valorVentaPublico = TextEditingController();
  final lote = TextEditingController();

  void save({
    required ValueChanged<Libro> onBookCreated,
    required VoidCallback onClose,
  }) {
    onBookCreated(
      Libro(
        nombre: nombre.text.trim(),
        nivel: nivel.text.trim(),
        tipo: int.tryParse(tipo.text.trim()) ?? 0,
        edicion: edicion.text.trim(),
        unidades: int.tryParse(unidades.text.trim()) ?? 0,
        valorCompra: int.tryParse(valorCompra.text.trim()) ?? 0,
        valorVentaPublico: int.tryParse(valorVentaPublico.text.trim()) ?? 0,
        lote: lote.text.trim(),
      ),
    );
    onClose();
  }

  void dispose() {
    for (final controller in [
      nombre,
      nivel,
      tipo,
      edicion,
      unidades,
      valorCompra,
      valorVentaPublico,
      lote,
    ]) {
      controller.dispose();
    }
  }
}

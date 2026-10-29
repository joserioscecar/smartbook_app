import 'package:flutter/material.dart';

import '../models/libro/libro_response.dart';

class LibrosFiltrados extends StatefulWidget {
  const LibrosFiltrados({
    super.key,
    required this.libros,
    required this.itemBuilder,
  });

  final List<LibroResponse> libros;
  final Widget Function(LibroResponse libro) itemBuilder;

  @override
  State<LibrosFiltrados> createState() => _LibrosFiltradosState();
}

class _LibrosFiltradosState extends State<LibrosFiltrados> {
  final _busqueda = TextEditingController();
  String? _nivel;
  String? _tipo;
  bool _soloDisponibles = false;

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  String _normalizar(String texto) {
    var resultado = texto.trim().toLowerCase();
    const acentos = {
      'á': 'a',
      'é': 'e',
      'í': 'i',
      'ó': 'o',
      'ú': 'u',
      'ü': 'u',
    };
    for (final entrada in acentos.entries) {
      resultado = resultado.replaceAll(entrada.key, entrada.value);
    }
    return resultado;
  }

  void _limpiar() => setState(() {
    _busqueda.clear();
    _nivel = null;
    _tipo = null;
    _soloDisponibles = false;
  });

  @override
  Widget build(BuildContext context) {
    final niveles = widget.libros.map((libro) => libro.nivel).toSet().toList()
      ..sort();
    final tipos =
        widget.libros
            .map((libro) => libro.tipo)
            .whereType<String>()
            .where((tipo) => tipo.trim().isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    // Si una recarga elimina la última opción seleccionada, vuelve a "Todos".
    if (!niveles.contains(_nivel)) _nivel = null;
    if (!tipos.contains(_tipo)) _tipo = null;
    final consulta = _normalizar(_busqueda.text);
    final filtrados = widget.libros.where((libro) {
      return (consulta.isEmpty ||
              _normalizar(libro.nombre).contains(consulta)) &&
          (_nivel == null || libro.nivel == _nivel) &&
          (_tipo == null || libro.tipo == _tipo) &&
          (!_soloDisponibles || (libro.stockTotal ?? 0) > 0);
    }).toList();
    final hayFiltros =
        consulta.isNotEmpty ||
        _nivel != null ||
        _tipo != null ||
        _soloDisponibles;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _busqueda,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: 'Filtrar por nombre',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: _busqueda.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Borrar búsqueda',
                    onPressed: () => setState(_busqueda.clear),
                    icon: const Icon(Icons.close_rounded),
                  ),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        _selector(
          'Nivel',
          _nivel,
          niveles,
          (valor) => setState(() => _nivel = valor),
        ),
        const SizedBox(height: 12),
        _selector(
          'Tipo',
          _tipo,
          tipos,
          (valor) => setState(() => _tipo = valor),
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Solo libros con stock'),
          value: _soloDisponibles,
          onChanged: (valor) =>
              setState(() => _soloDisponibles = valor ?? false),
          controlAffinity: ListTileControlAffinity.leading,
        ),
        if (hayFiltros)
          TextButton.icon(
            onPressed: _limpiar,
            icon: const Icon(Icons.filter_alt_off_outlined),
            label: const Text('Limpiar filtros'),
          ),
        Text('${filtrados.length} de ${widget.libros.length} libros'),
        const SizedBox(height: 12),
        if (filtrados.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text(
              'No hay libros que coincidan con los filtros.',
              textAlign: TextAlign.center,
            ),
          ),
        for (final libro in filtrados) widget.itemBuilder(libro),
      ],
    );
  }

  Widget _selector(
    String etiqueta,
    String? valor,
    List<String> opciones,
    ValueChanged<String?> onChanged,
  ) => InputDecorator(
    decoration: InputDecoration(
      labelText: etiqueta,
      border: const OutlineInputBorder(),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: valor,
        isExpanded: true,
        hint: const Text('Todos'),
        items: [
          const DropdownMenuItem<String>(value: null, child: Text('Todos')),
          for (final opcion in opciones)
            DropdownMenuItem(value: opcion, child: Text(opcion)),
        ],
        onChanged: onChanged,
      ),
    ),
  );
}

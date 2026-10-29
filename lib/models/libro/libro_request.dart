class CrearLibroRequest {
  final String nombre;
  final String nivel;
  final int tipo;
  final String edicion;
  final int unidades;
  final int valorCompra;
  final int valorVentaPublico;
  final String lote;

  const CrearLibroRequest({
    required this.nombre,
    required this.nivel,
    required this.tipo,
    required this.edicion,
    required this.unidades,
    required this.valorCompra,
    required this.valorVentaPublico,
    required this.lote,
  });

  Map<String, dynamic> toJson() => {
    'nombre': nombre,
    'nivel': nivel,
    'tipo': tipo,
    'edicion': edicion,
    'unidades': unidades,
    'valorCompra': valorCompra,
    'valorVentaPublico': valorVentaPublico,
    'lote': lote,
  };
}

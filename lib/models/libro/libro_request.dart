class CrearLibroRequest {
  final String nombre;
  final String nivel;
  final int tipo;
  final int unidades;
  final int lote;
  final int valorCompra;
  final int valorVentaPublico;

  const CrearLibroRequest({
    required this.nombre,
    required this.nivel,
    required this.tipo,
    required this.unidades,
    required this.lote,
    required this.valorCompra,
    required this.valorVentaPublico,
  });

  Map<String, dynamic> toJson() => {
    'nombre': nombre,
    'nivel': nivel,
    'tipo': tipo,
    'unidades': unidades,
    'lote': lote,
    'valorCompra': valorCompra,
    'valorVentaPublico': valorVentaPublico,
  };
}

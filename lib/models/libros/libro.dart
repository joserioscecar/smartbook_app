class Libro {
  const Libro({
    required this.nombre,
    required this.nivel,
    required this.tipo,
    required this.edicion,
    required this.unidades,
    required this.valorCompra,
    required this.valorVentaPublico,
    required this.lote,
  });

  final String nombre;
  final String nivel;
  final int tipo;
  final String edicion;
  final int unidades;
  final int valorCompra;
  final int valorVentaPublico;
  final String lote;

  factory Libro.fromJson(Map<String, dynamic> json) => Libro(
    nombre: json['nombre'] as String,
    nivel: json['nivel'] as String,
    tipo: (json['tipo'] as num).toInt(),
    edicion: json['edicion'] as String,
    unidades: (json['unidades'] as num).toInt(),
    valorCompra: (json['valorCompra'] as num).toInt(),
    valorVentaPublico: (json['valorVentaPublico'] as num).toInt(),
    lote: json['lote'] as String,
  );

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

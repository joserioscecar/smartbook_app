class LibroResponse {
  final int id;
  final String nombre;
  final String nivel;
  final int? stockTotal;
  final String? tipo;
  final String? edicion;
  final int? unidades;
  final num? valorCompra;
  final num? valorVentaPublico;
  final int? lote;

  const LibroResponse({
    required this.id,
    required this.nombre,
    required this.nivel,
    this.stockTotal,
    this.tipo,
    this.edicion,
    this.unidades,
    this.valorCompra,
    this.valorVentaPublico,
    this.lote,
  });

  static List<LibroResponse> fromJsonList(dynamic data) => (data as List)
      .map((item) => LibroResponse.fromJson(item as Map<String, dynamic>))
      .toList();
  factory LibroResponse.fromJson(Map<String, dynamic> json) => LibroResponse(
    id: json['id'] as int,
    nombre: json['nombre'] as String,
    nivel: json['nivel'] as String,
    stockTotal: json['stockTotal'] as int?,
    tipo: json['tipo']?.toString(),
    edicion: json['edicion'] as String?,
    unidades: json['unidades'] as int?,
    valorCompra: json['valorCompra'] as num?,
    valorVentaPublico: json['valorVentaPublico'] as num?,
    lote: json['lote'] as int?,
  );
}

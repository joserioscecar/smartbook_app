class VentaResponse {
  const VentaResponse({
    required this.id,
    required this.numeroRecibo,
    required this.numeroComprobante,
    required this.total,
    required this.fecha,
    required this.clienteNombre,
    required this.items,
  });

  final int id;
  final String numeroRecibo;
  final String numeroComprobante;
  final num total;
  final DateTime fecha;
  final String clienteNombre;
  final List<VentaItemResponse> items;

  factory VentaResponse.fromJson(Map<String, dynamic> json) => VentaResponse(
    id: json['id'] as int,
    numeroRecibo: json['numeroRecibo'] as String,
    numeroComprobante: json['numeroComprobante'] as String,
    total: json['total'] as num,
    fecha: DateTime.parse(json['fecha'] as String),
    clienteNombre: json['clienteNombre'] as String,
    items: (json['items'] as List)
        .map((item) => VentaItemResponse.fromJson(item as Map<String, dynamic>))
        .toList(),
  );
}

class VentaItemResponse {
  const VentaItemResponse({
    required this.libroId,
    required this.nombreLibro,
    required this.nivel,
    required this.lote,
    required this.cantidad,
    required this.precioUnitario,
    required this.subtotal,
  });

  final int libroId;
  final String nombreLibro;
  final String nivel;
  final int lote;
  final int cantidad;
  final num precioUnitario;
  final num subtotal;

  factory VentaItemResponse.fromJson(Map<String, dynamic> json) =>
      VentaItemResponse(
        libroId: json['libroId'] as int,
        nombreLibro: json['nombreLibro'] as String,
        nivel: json['nivel'] as String,
        lote: json['lote'] as int,
        cantidad: json['cantidad'] as int,
        precioUnitario: json['precioUnitario'] as num,
        subtotal: json['subtotal'] as num,
      );
}

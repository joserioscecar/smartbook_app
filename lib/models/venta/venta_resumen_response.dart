class VentaResumenResponse {
  const VentaResumenResponse({
    required this.id,
    required this.numeroRecibo,
    required this.numeroComprobante,
    required this.total,
    required this.fecha,
    required this.clienteNombre,
  });

  final int id;
  final String numeroRecibo;
  final String numeroComprobante;
  final num total;
  final DateTime fecha;
  final String clienteNombre;

  factory VentaResumenResponse.fromJson(Map<String, dynamic> json) =>
      VentaResumenResponse(
        id: json['id'] as int,
        numeroRecibo: json['numeroRecibo'] as String,
        numeroComprobante: json['numeroComprobante'] as String? ?? '',
        total: json['total'] as num,
        fecha: DateTime.parse(json['fecha'] as String),
        clienteNombre: json['clienteNombre'] as String,
      );

  static List<VentaResumenResponse> fromJsonList(dynamic data) => (data as List)
      .map(
        (item) => VentaResumenResponse.fromJson(item as Map<String, dynamic>),
      )
      .toList();
}

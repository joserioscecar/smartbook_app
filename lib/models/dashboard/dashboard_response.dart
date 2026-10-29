import '../venta/venta_response.dart';

class DashboardResponse {
  const DashboardResponse({
    required this.totalLibros,
    required this.totalClientes,
    required this.cantVentasMes,
    required this.totalVentasMes,
    required this.ventasHoy,
  });

  final int totalLibros;
  final int totalClientes;
  final int cantVentasMes;
  final num totalVentasMes;
  final List<VentaHoyResponse> ventasHoy;

  factory DashboardResponse.fromJson(Map<String, dynamic> json) =>
      DashboardResponse(
        totalLibros: json['totalLibros'] as int,
        totalClientes: json['totalClientes'] as int,
        cantVentasMes: json['cantVentasMes'] as int,
        totalVentasMes: json['totalVentasMes'] as num,
        ventasHoy: (json['ventasHoy'] as List)
            .map(
              (venta) =>
                  VentaHoyResponse.fromJson(venta as Map<String, dynamic>),
            )
            .toList(),
      );
}

class VentaHoyResponse {
  const VentaHoyResponse({
    required this.numeroRecibo,
    required this.total,
    required this.fecha,
    required this.items,
  });

  final String numeroRecibo;
  final num total;
  final DateTime fecha;
  final List<VentaItemResponse> items;

  factory VentaHoyResponse.fromJson(Map<String, dynamic> json) =>
      VentaHoyResponse(
        numeroRecibo: json['numeroRecibo'] as String,
        total: json['total'] as num,
        fecha: DateTime.parse(json['fecha'] as String),
        items: (json['items'] as List)
            .map(
              (item) =>
                  VentaItemResponse.fromJson(item as Map<String, dynamic>),
            )
            .toList(),
      );
}

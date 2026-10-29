class CrearVentaRequest {
  const CrearVentaRequest({
    required this.identificacionCliente,
    required this.numeroComprobante,
    required this.observaciones,
    required this.items,
  });

  Map<String, dynamic> toJson() => {
        'identificacionCliente': identificacionCliente,
        'numeroComprobante': numeroComprobante,
        'observaciones': observaciones,
        'items': items.map((item) => item.toJson()).toList(),
      };


  final String identificacionCliente;
  final String numeroComprobante;
  final String observaciones;
  final List<CrearVentaItemRequest> items;




}

class CrearVentaItemRequest {
  const CrearVentaItemRequest({
    required this.libroId,
    required this.lote,
    required this.cantidad,
  });

  final int libroId;
  final String lote;
  final int cantidad;

  Map<String, dynamic> toJson() => {
    'libroId': libroId,
    'lote': lote,
    'cantidad': cantidad,
  };
}

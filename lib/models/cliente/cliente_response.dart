class ClienteResponse {
  final String identificacion;
  final String nombres;
  final String email;
  final String celular;

  const ClienteResponse({
    required this.identificacion,
    required this.nombres,
    required this.email,
    required this.celular,
  });

  factory ClienteResponse.fromJson(Map<String, dynamic> json) =>
      ClienteResponse(
        identificacion: (json['identificacion'] as Object).toString(),
        nombres: json['nombres'] as String,
        email: json['email'] as String? ?? '',
        celular: json['celular']?.toString() ?? '',
      );

  static List<ClienteResponse> fromJsonList(dynamic data) => (data as List)
      .map((item) => ClienteResponse.fromJson(item as Map<String, dynamic>))
      .toList();
}

class EditarClienteRequest {
  final String nombres;
  final String? email;
  final String? celular;

  const EditarClienteRequest({required this.nombres, this.email, this.celular});

  Map<String, dynamic> toJson() => {
    'nombres': nombres,
    'email': email,
    'celular': celular,
  };
}

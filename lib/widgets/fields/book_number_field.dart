import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'custom_text_field.dart';

class BookNumberField extends StatelessWidget {
  const BookNumberField({
    required this.controller,
    required this.label,
    this.validator,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) => CustomTextField(
    controller: controller,
    label: label,
    keyboardType: TextInputType.number,
    textInputAction: TextInputAction.next,
    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    validator: validator,
  );
}

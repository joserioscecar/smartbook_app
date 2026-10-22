import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'custom_text_field.dart';

class BookNumberField extends StatelessWidget {
  const BookNumberField({
    required this.controller,
    required this.label,
    super.key,
  });

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) => CustomTextField(
    controller: controller,
    label: label,
    keyboardType: TextInputType.number,
    textInputAction: TextInputAction.next,
    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
  );
}

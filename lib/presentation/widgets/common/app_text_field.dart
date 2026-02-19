import 'package:flutter/material.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.label,
    this.controller,
    this.obscureText = false,
  });
  final String? label;
  final TextEditingController? controller;
  final bool obscureText;

  @override
  Widget build(BuildContext context) => const Placeholder();
}

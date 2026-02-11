import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NumericPasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final int length;
  final Color color;
  final String? Function(String?)? validator;
  final TextEditingController? confirmController; // pour confirmation

  const NumericPasswordField({
    super.key,
    required this.controller,
    this.confirmController,
    this.hint = 'Mot de passe',
    this.length = 4,
    this.color = const Color.fromARGB(255, 8, 72, 190),
    this.validator,
  });

  @override
  State<NumericPasswordField> createState() => _NumericPasswordFieldState();
}

class _NumericPasswordFieldState extends State<NumericPasswordField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly , LengthLimitingTextInputFormatter(4),],
      obscureText: _obscureText,
      style: TextStyle(
        color: widget.color,
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: const TextStyle(
          color: Colors.grey,
          fontSize: 16,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: const Color(0xFFF1F5F9),
        suffixIcon: IconButton(
          icon: Icon(
            _obscureText ? Icons.visibility_off : Icons.visibility,
            color: widget.color,
          ),
          onPressed: () {
            setState(() {
              _obscureText = !_obscureText;
            });
          },
        ),
      ),
      validator: widget.validator ??
              (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez entrer un mot de passe';
            }
            if (value.length != widget.length) {
              return 'Le mot de passe doit contenir ${widget.length} chiffres';
            }
            if (widget.confirmController != null &&
                value != widget.confirmController!.text) {
              return 'Les mots de passe ne correspondent pas';
            }
            return null;
          },
    );
  }
}

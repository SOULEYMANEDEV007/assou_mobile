// Custom Input Field matching ASSOU design
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppInput extends StatefulWidget {
  final String? label;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType keyboardType;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixIconPressed;
  final Function(String)? onChanged;
  final String? Function(String?)? validator;
  final bool enabled;
  final int? maxLines;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final bool readOnly;
  final Widget? prefixWidget;
  final bool showDivider;

  const AppInput({
    super.key,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.controller,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixIconPressed,
    this.onChanged,
    this.validator,
    this.enabled = true,
    this.maxLines = 1,
    this.maxLength,
    this.inputFormatters,
    this.readOnly = false,
    this.prefixWidget,
    this.showDivider = false,
  });

  @override
  State<AppInput> createState() => _AppInputState();
}

class _AppInputState extends State<AppInput> {
  late bool _isObscured;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _isObscured = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1E293B),
              fontFamily: 'Nunito',
            ),
          ),
          const SizedBox(height: 8),
        ],
        Focus(
          onFocusChange: (hasFocus) {
            setState(() {
              _isFocused = hasFocus;
            });
          },
          child: TextFormField(
            controller: widget.controller,
            obscureText: _isObscured,
            keyboardType: widget.keyboardType,
            onChanged: widget.onChanged,
            validator: widget.validator,
            enabled: widget.enabled,
            maxLines: widget.maxLines,
            maxLength: widget.maxLength,
            inputFormatters: widget.inputFormatters,
            readOnly: widget.readOnly,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Color(0xFF1E293B),
              fontFamily: 'Nunito',
            ),
            decoration: InputDecoration(
              hintText: widget.hint,
              counterText: '',
              filled: true,
              fillColor: widget.enabled
                  ? const Color(0xFFF1F5F9)
                  : const Color(0xFFF8FAFC),

              // Borders
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: widget.errorText != null
                    ? const BorderSide(color: Color(0xFFEF4444), width: 1)
                    : BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: widget.errorText != null
                    ? const BorderSide(color: Color(0xFFEF4444), width: 2)
                    : const BorderSide(color: Color(0xFF3380fe), width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide:
                    const BorderSide(color: Color(0xFFEF4444), width: 1),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide:
                    const BorderSide(color: Color(0xFFEF4444), width: 2),
              ),

              // Content padding
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 18,
              ),

              // Icons
              prefixIcon: widget.prefixWidget != null
                  ? Container(
                      padding: const EdgeInsets.only(left: 12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          widget.prefixWidget!,
                          if (widget.showDivider) ...[
                            const SizedBox(width: 12),
                            Container(
                              width: 1.5,
                              height: 24,
                              color: Theme.of(context)
                                  .dividerColor
                                  .withOpacity(0.2),
                            ),
                            const SizedBox(width: 8),
                          ],
                        ],
                      ),
                    )
                  : widget.prefixIcon != null
                      ? Icon(
                          widget.prefixIcon,
                          color: _isFocused
                              ? const Color(0xFF3380fe)
                              : const Color(0xFF64748B),
                          size: 20,
                        )
                      : null,
              prefixIconConstraints: const BoxConstraints(
                minWidth: 0,
                minHeight: 0,
              ),
              suffixIcon: _buildSuffixIcon(),

              // Text styles
              hintStyle: const TextStyle(
                fontSize: 16,
                color: Color(0xFF94A3B8),
                fontWeight: FontWeight.w400,
                fontFamily: 'Nunito',
              ),

              // Error style
              errorStyle: const TextStyle(
                fontSize: 12,
                color: Color(0xFFEF4444),
                fontWeight: FontWeight.w400,
                fontFamily: 'Nunito',
              ),
            ),
          ),
        ),
        if (widget.helperText != null && widget.errorText == null) ...[
          const SizedBox(height: 6),
          Text(
            widget.helperText!,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              fontFamily: 'Nunito',
            ),
          ),
        ],
        if (widget.errorText != null) ...[
          const SizedBox(height: 6),
          Text(
            widget.errorText!,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFFEF4444),
              fontWeight: FontWeight.w500,
              fontFamily: 'Nunito',
            ),
          ),
        ],
      ],
    );
  }

  Widget? _buildSuffixIcon() {
    if (widget.obscureText) {
      return IconButton(
        onPressed: () {
          setState(() {
            _isObscured = !_isObscured;
          });
        },
        icon: Icon(
          _isObscured ? Icons.visibility_off : Icons.visibility,
          color: const Color(0xFF64748B),
          size: 20,
        ),
      );
    } else if (widget.suffixIcon != null) {
      return IconButton(
        onPressed: widget.onSuffixIconPressed,
        icon: Icon(
          widget.suffixIcon,
          color: const Color(0xFF64748B),
          size: 20,
        ),
      );
    }
    return null;
  }
}

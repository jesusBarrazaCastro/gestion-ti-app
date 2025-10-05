import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Input extends FormField<String> {
  final String? hintText;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final String? labelText;
  final TextStyle? labelStyle;
  final Color? backgroundColor;
  final TextStyle? textStyle;
  final TextStyle? hintStyle;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Color? borderColor;
  final double borderWidth;
  final bool isPassword;
  final bool required;
  final bool enabled;
  final int? maxLines;
  final List<TextInputFormatter>? inputFormatters;
  final TextAlign? textAlign;
  final void Function(String)? onChanged; // Callback onChanged agregado

  Input({
    Key? key,
    this.hintText,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.labelText,
    this.labelStyle,
    this.backgroundColor,
    this.textStyle,
    this.hintStyle,
    this.width,
    this.height = 40,
    this.borderRadius,
    this.borderColor,
    this.borderWidth = 2.0,
    this.isPassword = false,
    this.required = false,
    this.enabled = true,
    this.maxLines = 1,
    this.inputFormatters,
    this.textAlign,
    this.onChanged, // Inicializa el callback
  }) : super(
    key: key,
    validator: (value) {
      if (required && (value == null || value.isEmpty)) {
        return 'Campo requerido.';
      }
      return null;
    },
    builder: (FormFieldState<String> state) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (labelText != null)
            Text(
              labelText!,
              style: labelStyle ??
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          const SizedBox(height: 8),
          SizedBox(
            width: width,
            height: height,
            child: TextField(
              controller: controller,
              obscureText: isPassword,
              keyboardType: keyboardType,
              enabled: enabled,
              maxLines: maxLines,
              textAlign: textAlign ?? TextAlign.start,
              style: textStyle ?? const TextStyle(color: Colors.black),
              inputFormatters: inputFormatters,
              decoration: InputDecoration(
                hintText: hintText ?? '',
                hintStyle: hintStyle ?? const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: backgroundColor ?? Colors.white,
                contentPadding:
                const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: borderRadius ?? BorderRadius.circular(8.0),
                  borderSide: BorderSide(
                    color: state.hasError
                        ? Colors.red
                        : borderColor ?? Theme.of(state.context).primaryColor,
                    width: borderWidth,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: borderRadius ?? BorderRadius.circular(8.0),
                  borderSide: BorderSide(
                    color: state.hasError
                        ? Colors.red
                        : borderColor ?? Theme.of(state.context).primaryColor,
                    width: borderWidth,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: borderRadius ?? BorderRadius.circular(8.0),
                  borderSide: BorderSide(
                    color: state.hasError
                        ? Colors.red
                        : borderColor ?? Theme.of(state.context).primaryColor,
                    width: borderWidth,
                  ),
                ),
                errorText: state.hasError ? state.errorText : null,
              ),
              onChanged: (value) {
                state.didChange(value); // Disparar validación
                if (onChanged != null) {
                  Future.microtask(() => onChanged!(value)); // Ensure execution in the next frame
                }
              },
            ),
          ),
        ],
      );
    },
  );
}

import 'package:flutter/material.dart';

class Dropdown<T> extends StatelessWidget {
  final String? labelText;
  final TextStyle? labelStyle;
  final List<DropdownMenuItem<T>> items;
  final T? value;
  final ValueChanged<T?> onChanged;
  final Color? backgroundColor;
  final TextStyle? textStyle;
  final Color? dropdownColor;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Color? borderColor;
  final double borderWidth;

  const Dropdown({
    Key? key,
    required this.items,
    required this.onChanged,
    this.value,
    this.labelText,
    this.labelStyle,
    this.backgroundColor,
    this.textStyle,
    this.dropdownColor,
    this.width,
    this.height,
    this.borderRadius,
    this.borderColor,
    this.borderWidth = 2.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (labelText != null)
          Text(
            labelText!,
            style: labelStyle ?? const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        const SizedBox(height: 8),  // Space between label and dropdown
        SizedBox(
          width: width,
          height: height,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: backgroundColor ?? Colors.white,
              borderRadius: borderRadius ?? BorderRadius.circular(8.0),
              border: Border.all(
                color: borderColor ?? Theme.of(context).primaryColor,
                width: borderWidth,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<T>(
                  value: value,
                  items: items,
                  onChanged: onChanged,
                  isExpanded: true,
                  dropdownColor: dropdownColor ?? backgroundColor ?? Colors.white,
                  style: textStyle ?? const TextStyle(color: Colors.black),
                  icon: Icon(Icons.arrow_drop_down, color: borderColor ?? Theme.of(context).primaryColor),
                  borderRadius: borderRadius ?? BorderRadius.circular(8.0),
                  // Padding to match design with other widgets
                  itemHeight: height != null ? height! - 16 : null,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

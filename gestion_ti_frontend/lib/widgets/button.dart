import 'package:flutter/material.dart';

class Button extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final TextStyle? textStyle;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Icon? icon;

  const Button({
    Key? key,
    required this.text,
    required this.onPressed,
    this.backgroundColor,
    this.textStyle,
    this.width,
    this.height,
    this.borderRadius,
    this.icon
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? Theme.of(context).primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: borderRadius ?? BorderRadius.circular(8.0),
          ),
        ),
        onPressed: onPressed,
        child: Row(
          children: [
            if(icon != null)...[
              icon!,
              const SizedBox(width: 10,)
            ],
            Text(
              text,
              style: textStyle ?? const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

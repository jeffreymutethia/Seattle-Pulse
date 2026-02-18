import 'package:flutter/material.dart';
import 'package:seattle_pulse_mobile/src/core/constants/colors.dart';

class AppInputField extends StatelessWidget {
  final TextEditingController? controller;
  final String hintText;
  final String labelText;
  final TextInputType keyboardType;
  bool obscureText;
  final TextInputAction textInputAction;
  final Icon? prefixIcon;
  final Icon? suffixIcon;
  final TextStyle? hintStyle;
  final TextStyle? labelStyle;
  final TextStyle? textStyle;
  final Color? borderColor;
  final Color? focusedBorderColor;
  final Color? fillColor;
  final EdgeInsetsGeometry? contentPadding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final bool isEnabled;
  final Function(String)? onChanged;
  final Function()? onTap;
  final Function()? onSuffix;
  final bool isPasswordField;
  final bool autoFocus;
  final String? Function(String?)? validator;

  AppInputField({
    this.controller,
    required this.hintText,
    required this.labelText,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.textInputAction = TextInputAction.done,
    this.prefixIcon,
    this.suffixIcon,
    this.hintStyle,
    this.labelStyle,
    this.textStyle,
    this.borderColor,
    this.focusedBorderColor,
    this.fillColor,
    this.contentPadding,
    this.margin,
    this.borderRadius = 10.0,
    this.isEnabled = true,
    this.onChanged,
    this.onTap,
    this.isPasswordField = false,
    this.autoFocus = false,
    this.onSuffix,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 50,
      margin:
          margin ?? const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: isPasswordField ? obscureText : false,
        autofocus: autoFocus,
        textInputAction: textInputAction,
        onChanged: onChanged,
        onTap: onTap,
        enabled: isEnabled,
        validator: validator,
        style: textStyle ?? const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          contentPadding: contentPadding ??
              const EdgeInsets.symmetric(
                vertical: 15,
                horizontal: 25,
              ),
          hintText: hintText,

          // labelText: labelText,
          hintStyle: hintStyle ??
              TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: AppColor.color838B98,
              ),
          labelStyle:
              labelStyle ?? const TextStyle(fontSize: 18, color: Colors.black),
          prefixIcon: prefixIcon,
          suffixIcon: isPasswordField
              ? IconButton(
                  icon: Icon(
                      obscureText ? Icons.visibility : Icons.visibility_off),
                  onPressed: () {
                    obscureText = !obscureText;
                    if (onSuffix != null) {
                      onSuffix!();
                    }
                  },
                )
              : suffixIcon,
          filled: true,
          fillColor: fillColor ?? Colors.white,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: BorderSide(
              color: borderColor ?? Colors.grey,
              width: 1.5,
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: BorderSide(
              color: borderColor ?? Colors.grey,
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: BorderSide(
              color: focusedBorderColor ?? Colors.black,
              width: 2.0,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: const BorderSide(
              color: Colors.red,
              width: 1.5,
            ),
          ),

          /// Red border when focused and has an error
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: BorderSide(
              color: Colors.red,
              width: 2.0,
            ),
          ),
        ),
      ),
    );
  }
}

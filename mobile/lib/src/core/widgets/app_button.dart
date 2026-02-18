import 'package:flutter/material.dart';

// Enum to define button type
enum ButtonType { primary, secondary }

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color textColor;
  final double borderRadius;
  final double elevation;
  final double paddingVertical;
  final double paddingHorizontal;
  final Icon? icon;
  final bool isLoading;
  final Color? loadingIndicatorColor;
  final double fontSize;
  final bool isEnabled;
  final TextStyle? textStyle;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? contentPadding;
  final bool isFullWidth;
  final ButtonType buttonType;
  final Color? borderColor;
  final String? image;
  final double? width;
  final double? height;
  final FontWeight? fontWeight;
  final bool? isIconLeft;

  AppButton({
    required this.text,
    required this.onPressed,
    this.image,
    this.backgroundColor = Colors.black,
    this.textColor = Colors.white,
    this.borderRadius = 8.0,
    this.elevation = 2.0,
    this.paddingVertical = 12.0,
    this.paddingHorizontal = 24.0,
    this.icon,
    this.isLoading = false,
    this.loadingIndicatorColor,
    this.fontSize = 16.0,
    this.isEnabled = true,
    this.textStyle,
    this.margin,
    this.contentPadding,
    this.isFullWidth = false,
    this.buttonType = ButtonType.primary,
    this.borderColor,
    this.width,
    this.height = 50.0,
    this.fontWeight,
    this.isIconLeft = true,
  });

  @override
  Widget build(BuildContext context) {
    // Full width setup if `isFullWidth` is true
    double? buttonWidth = isFullWidth ? double.infinity : (width ?? null);

    // Button Style Configuration based on the button type
    BoxDecoration buttonDecoration;
    if (buttonType == ButtonType.primary) {
      buttonDecoration = BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
      );
    } else {
      buttonDecoration = BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor ?? backgroundColor,
          width: 2,
        ),
      );
    }

    return Container(
      margin: margin ?? EdgeInsets.all(0.0),
      width: buttonWidth,
      height: height,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEnabled ? onPressed : null,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Container(
            padding: contentPadding ??
                EdgeInsets.symmetric(
                  vertical: paddingVertical,
                  horizontal: paddingHorizontal,
                ),
            decoration: buttonDecoration,
            child: isLoading
                ? Container(
                    height: 10,
                    width: 10,
                    margin: EdgeInsets.symmetric(horizontal: 140.0),
                    // color: Colors.amberAccent,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.0,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        loadingIndicatorColor ?? textColor,
                      ),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isIconLeft == false) ...[
                        if (icon != null) ...[
                          icon!,
                          SizedBox(width: 8.0), // Spacer between icon and text
                        ],
                        if (image != null) ...[
                          Image.network(
                            image!,
                            height: fontSize + 10,
                          ),
                          SizedBox(width: 8.0), // Spacer between icon and text
                        ],
                      ],
                      Text(
                        text,
                        style: textStyle ??
                            TextStyle(
                              fontSize: fontSize,
                              fontWeight: fontWeight ?? FontWeight.w500,
                              color: buttonType == ButtonType.primary
                                  ? textColor
                                  : borderColor ?? backgroundColor,
                            ),
                      ),
                      if (isIconLeft == true) ...[
                        if (icon != null) ...[
                          SizedBox(width: 8.0),
                          icon!,
                          // Spacer between icon and text
                        ],
                        if (image != null) ...[
                          SizedBox(width: 8.0),
                          Image.network(
                            image!,
                            height: fontSize + 10,
                          ),
                        ],
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

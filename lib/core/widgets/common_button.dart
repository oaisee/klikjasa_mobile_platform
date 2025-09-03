import 'package:flutter/material.dart';
import 'package:klik_jasa/core/constants/app_colors.dart';

/// Widget Button yang dapat digunakan kembali untuk mengurangi duplikasi kode
class CommonButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isEnabled;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final Widget? icon;
  final double? fontSize;
  final FontWeight? fontWeight;

  const CommonButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height,
    this.padding,
    this.borderRadius,
    this.icon,
    this.fontSize,
    this.fontWeight,
  });

  /// Factory constructor untuk button primary
  factory CommonButton.primary({
    required String text,
    VoidCallback? onPressed,
    bool isLoading = false,
    bool isEnabled = true,
    double? width,
    double? height,
    Widget? icon,
  }) {
    return CommonButton(
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      isEnabled: isEnabled,
      backgroundColor: AppColors.primary,
      textColor: Colors.white,
      width: width,
      height: height ?? 48,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      borderRadius: BorderRadius.circular(12),
      icon: icon,
      fontSize: 16,
      fontWeight: FontWeight.w600,
    );
  }

  /// Factory constructor untuk button secondary
  factory CommonButton.secondary({
    required String text,
    VoidCallback? onPressed,
    bool isLoading = false,
    bool isEnabled = true,
    double? width,
    double? height,
    Widget? icon,
  }) {
    return CommonButton(
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      isEnabled: isEnabled,
      backgroundColor: AppColors.secondary,
      textColor: AppColors.primary,
      width: width,
      height: height ?? 48,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      borderRadius: BorderRadius.circular(12),
      icon: icon,
      fontSize: 16,
      fontWeight: FontWeight.w500,
    );
  }

  /// Factory constructor untuk button outline
  factory CommonButton.outline({
    required String text,
    VoidCallback? onPressed,
    bool isLoading = false,
    bool isEnabled = true,
    double? width,
    double? height,
    Widget? icon,
    Color borderColor = AppColors.primary,
  }) {
    return CommonButton(
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      isEnabled: isEnabled,
      backgroundColor: Colors.transparent,
      textColor: borderColor,
      width: width,
      height: height ?? 48,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      borderRadius: BorderRadius.circular(12),
      icon: icon,
      fontSize: 16,
      fontWeight: FontWeight.w500,
    );
  }

  /// Factory constructor untuk button danger
  factory CommonButton.danger({
    required String text,
    VoidCallback? onPressed,
    bool isLoading = false,
    bool isEnabled = true,
    double? width,
    double? height,
    Widget? icon,
  }) {
    return CommonButton(
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      isEnabled: isEnabled,
      backgroundColor: Colors.red,
      textColor: Colors.white,
      width: width,
      height: height ?? 48,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      borderRadius: BorderRadius.circular(12),
      icon: icon,
      fontSize: 16,
      fontWeight: FontWeight.w600,
    );
  }

  /// Factory constructor untuk button text only
  factory CommonButton.text({
    required String text,
    VoidCallback? onPressed,
    bool isLoading = false,
    bool isEnabled = true,
    Color? textColor,
    Widget? icon,
  }) {
    return CommonButton(
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      isEnabled: isEnabled,
      backgroundColor: Colors.transparent,
      textColor: textColor ?? AppColors.primary,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      borderRadius: BorderRadius.circular(8),
      icon: icon,
      fontSize: 14,
      fontWeight: FontWeight.w500,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isButtonEnabled = isEnabled && !isLoading && onPressed != null;

    Widget buttonChild = isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                textColor ?? Colors.white,
              ),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                icon!,
                const SizedBox(width: 8),
              ],
              Text(
                text,
                style: TextStyle(
                  color: isButtonEnabled
                      ? textColor ?? Colors.white
                      : Colors.grey[400],
                  fontSize: fontSize ?? 16,
                  fontWeight: fontWeight ?? FontWeight.w500,
                ),
              ),
            ],
          );

    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: isButtonEnabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: isButtonEnabled
              ? backgroundColor ?? AppColors.primary
              : Colors.grey[300],
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: borderRadius ?? BorderRadius.circular(12),
            side: backgroundColor == Colors.transparent
                ? BorderSide(
                    color: isButtonEnabled
                        ? textColor ?? AppColors.primary
                        : Colors.grey[400]!,
                    width: 1,
                  )
                : BorderSide.none,
          ),
          elevation: backgroundColor == Colors.transparent ? 0 : 2,
        ),
        child: buttonChild,
      ),
    );
  }
}

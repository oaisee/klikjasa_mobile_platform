import 'package:flutter/material.dart';
import 'package:klik_jasa/core/constants/app_colors.dart';

/// Widget Container dengan BoxDecoration yang dapat digunakan kembali untuk mengurangi duplikasi kode
class CommonContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;
  final Border? border;
  final List<BoxShadow>? boxShadow;
  final Gradient? gradient;
  final VoidCallback? onTap;

  const CommonContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.margin,
    this.padding,
    this.backgroundColor,
    this.borderRadius,
    this.border,
    this.boxShadow,
    this.gradient,
    this.onTap,
  });

  /// Factory constructor untuk container dengan shadow default
  factory CommonContainer.withShadow({
    required Widget child,
    double? width,
    double? height,
    EdgeInsetsGeometry? margin,
    EdgeInsetsGeometry? padding,
    Color? backgroundColor,
    BorderRadius? borderRadius,
    VoidCallback? onTap,
  }) {
    return CommonContainer(
      width: width,
      height: height,
      margin: margin ?? const EdgeInsets.all(8),
      padding: padding ?? const EdgeInsets.all(16),
      backgroundColor: backgroundColor ?? Colors.white,
      borderRadius: borderRadius ?? BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
      onTap: onTap,
      child: child,
    );
  }

  /// Factory constructor untuk container dengan border
  factory CommonContainer.withBorder({
    required Widget child,
    double? width,
    double? height,
    EdgeInsetsGeometry? margin,
    EdgeInsetsGeometry? padding,
    Color? backgroundColor,
    BorderRadius? borderRadius,
    Color? borderColor,
    double borderWidth = 1,
    VoidCallback? onTap,
  }) {
    return CommonContainer(
      width: width,
      height: height,
      margin: margin ?? const EdgeInsets.all(8),
      padding: padding ?? const EdgeInsets.all(16),
      backgroundColor: backgroundColor ?? Colors.white,
      borderRadius: borderRadius ?? BorderRadius.circular(12),
      border: Border.all(color: borderColor ?? AppColors.border, width: borderWidth),
      onTap: onTap,
      child: child,
    );
  }

  /// Factory constructor untuk container dengan gradient
  factory CommonContainer.withGradient({
    required Widget child,
    required Gradient gradient,
    double? width,
    double? height,
    EdgeInsetsGeometry? margin,
    EdgeInsetsGeometry? padding,
    BorderRadius? borderRadius,
    VoidCallback? onTap,
  }) {
    return CommonContainer(
      width: width,
      height: height,
      margin: margin ?? const EdgeInsets.all(8),
      padding: padding ?? const EdgeInsets.all(16),
      borderRadius: borderRadius ?? BorderRadius.circular(12),
      gradient: gradient,
      onTap: onTap,
      child: child,
    );
  }

  /// Factory constructor untuk container rounded
  factory CommonContainer.rounded({
    required Widget child,
    double? width,
    double? height,
    EdgeInsetsGeometry? margin,
    EdgeInsetsGeometry? padding,
    Color? backgroundColor,
    double radius = 20,
    VoidCallback? onTap,
  }) {
    return CommonContainer(
      width: width,
      height: height,
      margin: margin ?? const EdgeInsets.all(8),
      padding: padding ?? const EdgeInsets.all(16),
      backgroundColor: backgroundColor ?? Colors.white,
      borderRadius: BorderRadius.circular(radius),
      onTap: onTap,
      child: child,
    );
  }

  /// Factory constructor untuk container dengan style card
  factory CommonContainer.card({
    required Widget child,
    double? width,
    double? height,
    EdgeInsetsGeometry? margin,
    EdgeInsetsGeometry? padding,
    VoidCallback? onTap,
  }) {
    return CommonContainer(
      width: width,
      height: height,
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: padding ?? const EdgeInsets.all(16),
      backgroundColor: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ],
      onTap: onTap,
      child: child,
    );
  }

  /// Factory constructor untuk container dengan style primary
  factory CommonContainer.primary({
    required Widget child,
    double? width,
    double? height,
    EdgeInsetsGeometry? margin,
    EdgeInsetsGeometry? padding,
    BorderRadius? borderRadius,
    VoidCallback? onTap,
  }) {
    return CommonContainer(
      width: width,
      height: height,
      margin: margin ?? const EdgeInsets.all(8),
      padding: padding ?? const EdgeInsets.all(16),
      backgroundColor: AppColors.primary,
      borderRadius: borderRadius ?? BorderRadius.circular(12),
      onTap: onTap,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget containerWidget = Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? backgroundColor : null,
        gradient: gradient,
        borderRadius: borderRadius,
        border: border,
        boxShadow: boxShadow,
      ),
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: containerWidget,
      );
    }

    return containerWidget;
  }
}

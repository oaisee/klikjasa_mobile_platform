import 'package:flutter/material.dart';

/// Widget Card yang dapat digunakan kembali untuk mengurangi duplikasi kode
class CommonCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final double? elevation;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final bool hasShadow;

  const CommonCard({
    super.key,
    required this.child,
    this.margin,
    this.padding,
    this.elevation,
    this.borderRadius,
    this.backgroundColor,
    this.onTap,
    this.hasShadow = true,
  });

  /// Factory constructor untuk card dengan style default
  factory CommonCard.defaultStyle({
    required Widget child,
    EdgeInsetsGeometry? margin,
    EdgeInsetsGeometry? padding,
    VoidCallback? onTap,
  }) {
    return CommonCard(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: padding ?? const EdgeInsets.all(16),
      elevation: 2,
      borderRadius: BorderRadius.circular(12),
      backgroundColor: Colors.white,
      onTap: onTap,
      child: child,
    );
  }

  /// Factory constructor untuk card dengan style minimal
  factory CommonCard.minimal({
    required Widget child,
    EdgeInsetsGeometry? margin,
    EdgeInsetsGeometry? padding,
    VoidCallback? onTap,
  }) {
    return CommonCard(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: padding ?? const EdgeInsets.all(12),
      elevation: 1,
      borderRadius: BorderRadius.circular(8),
      backgroundColor: Colors.white,
      onTap: onTap,
      hasShadow: false,
      child: child,
    );
  }

  /// Factory constructor untuk card dengan style elevated
  factory CommonCard.elevated({
    required Widget child,
    EdgeInsetsGeometry? margin,
    EdgeInsetsGeometry? padding,
    VoidCallback? onTap,
  }) {
    return CommonCard(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: padding ?? const EdgeInsets.all(20),
      elevation: 4,
      borderRadius: BorderRadius.circular(16),
      backgroundColor: Colors.white,
      onTap: onTap,
      child: child,
    );
  }

  /// Factory constructor untuk card dengan style outline
  factory CommonCard.outlined({
    required Widget child,
    EdgeInsetsGeometry? margin,
    EdgeInsetsGeometry? padding,
    VoidCallback? onTap,
    Color borderColor = Colors.grey,
  }) {
    return CommonCard(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: padding ?? const EdgeInsets.all(16),
      elevation: 0,
      borderRadius: BorderRadius.circular(12),
      backgroundColor: Colors.white,
      onTap: onTap,
      hasShadow: false,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: borderColor, width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget cardWidget = Card(
      margin: margin,
      elevation: hasShadow ? (elevation ?? 2) : 0,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius ?? BorderRadius.circular(12),
      ),
      color: backgroundColor ?? Colors.white,
      child: padding != null
          ? Padding(
              padding: padding!,
              child: child,
            )
          : child,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: borderRadius ?? BorderRadius.circular(12),
        child: cardWidget,
      );
    }

    return cardWidget;
  }
}

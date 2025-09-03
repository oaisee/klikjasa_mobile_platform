import 'package:flutter/material.dart';
import 'package:klik_jasa/core/constants/app_colors.dart';

/// Custom button widget dengan berbagai variasi style
/// 
/// Widget ini menyediakan button dengan style yang konsisten
/// dan dapat dikustomisasi sesuai kebutuhan aplikasi.
class CustomButton extends StatelessWidget {
  /// Text yang ditampilkan di button
  final String text;
  
  /// Fungsi yang dipanggil ketika button ditekan
  final VoidCallback? onPressed;
  
  /// Apakah button sedang dalam state loading
  final bool isLoading;
  
  /// Tipe button (primary, secondary, outline, text)
  final ButtonType type;
  
  /// Ukuran button (small, medium, large)
  final ButtonSize size;
  
  /// Lebar button (null untuk mengikuti content, double.infinity untuk full width)
  final double? width;
  
  /// Ikon yang ditampilkan di sebelah kiri text (opsional)
  final IconData? icon;
  
  /// Warna custom untuk button (opsional)
  final Color? color;

  /// Konstruktor untuk CustomButton
  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.type = ButtonType.primary,
    this.size = ButtonSize.medium,
    this.width,
    this.icon,
    this.color,
  });

  /// Factory constructor untuk primary button
  factory CustomButton.primary({
    Key? key,
    required String text,
    VoidCallback? onPressed,
    bool isLoading = false,
    ButtonSize size = ButtonSize.medium,
    double? width,
    IconData? icon,
  }) {
    return CustomButton(
      key: key,
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      type: ButtonType.primary,
      size: size,
      width: width,
      icon: icon,
    );
  }

  /// Factory constructor untuk secondary button
  factory CustomButton.secondary({
    Key? key,
    required String text,
    VoidCallback? onPressed,
    bool isLoading = false,
    ButtonSize size = ButtonSize.medium,
    double? width,
    IconData? icon,
  }) {
    return CustomButton(
      key: key,
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      type: ButtonType.secondary,
      size: size,
      width: width,
      icon: icon,
    );
  }

  /// Factory constructor untuk outline button
  factory CustomButton.outline({
    Key? key,
    required String text,
    VoidCallback? onPressed,
    bool isLoading = false,
    ButtonSize size = ButtonSize.medium,
    double? width,
    IconData? icon,
    Color? color,
  }) {
    return CustomButton(
      key: key,
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      type: ButtonType.outline,
      size: size,
      width: width,
      icon: icon,
      color: color,
    );
  }

  /// Factory constructor untuk text button
  factory CustomButton.text({
    Key? key,
    required String text,
    VoidCallback? onPressed,
    bool isLoading = false,
    ButtonSize size = ButtonSize.medium,
    double? width,
    IconData? icon,
    Color? color,
  }) {
    return CustomButton(
      key: key,
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      type: ButtonType.text,
      size: size,
      width: width,
      icon: icon,
      color: color,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determine button style based on type
    ButtonStyle buttonStyle;
    Color textColor;
    
    switch (type) {
      case ButtonType.primary:
        buttonStyle = ElevatedButton.styleFrom(
          backgroundColor: color ?? AppColors.primary,
          foregroundColor: AppColors.white,
          elevation: 2,
          shadowColor: AppColors.shadowLight,
        );
        textColor = AppColors.white;
        break;
        
      case ButtonType.secondary:
        buttonStyle = ElevatedButton.styleFrom(
          backgroundColor: color ?? AppColors.accent,
          foregroundColor: AppColors.white,
          elevation: 1,
        );
        textColor = AppColors.white;
        break;
        
      case ButtonType.outline:
        buttonStyle = OutlinedButton.styleFrom(
          foregroundColor: color ?? AppColors.primary,
          side: BorderSide(color: color ?? AppColors.primary),
          backgroundColor: Colors.transparent,
        );
        textColor = color ?? AppColors.primary;
        break;
        
      case ButtonType.text:
        buttonStyle = TextButton.styleFrom(
          foregroundColor: color ?? AppColors.primary,
          backgroundColor: Colors.transparent,
        );
        textColor = color ?? AppColors.primary;
        break;
    }
    
    // Determine button size
    EdgeInsets padding;
    double fontSize;
    double height;
    
    switch (size) {
      case ButtonSize.small:
        padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
        fontSize = 12;
        height = 32;
        break;
        
      case ButtonSize.medium:
        padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
        fontSize = 14;
        height = 44;
        break;
        
      case ButtonSize.large:
        padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 16);
        fontSize = 16;
        height = 52;
        break;
    }
    
    // Update button style with size
    buttonStyle = buttonStyle.copyWith(
      padding: WidgetStateProperty.all(padding),
      minimumSize: WidgetStateProperty.all(Size(0, height)),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      textStyle: WidgetStateProperty.all(
        TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          fontFamily: 'Poppins',
        ),
      ),
    );
    
    Widget buttonChild;
    
    if (isLoading) {
      buttonChild = SizedBox(
        height: fontSize + 4,
        width: fontSize + 4,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(textColor),
        ),
      );
    } else if (icon != null) {
      buttonChild = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: fontSize + 2),
          const SizedBox(width: 8),
          Text(text),
        ],
      );
    } else {
      buttonChild = Text(text);
    }
    
    Widget button;
    
    switch (type) {
      case ButtonType.primary:
      case ButtonType.secondary:
        button = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: buttonStyle,
          child: buttonChild,
        );
        break;
        
      case ButtonType.outline:
        button = OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: buttonStyle,
          child: buttonChild,
        );
        break;
        
      case ButtonType.text:
        button = TextButton(
          onPressed: isLoading ? null : onPressed,
          style: buttonStyle,
          child: buttonChild,
        );
        break;
    }
    
    if (width != null) {
      return SizedBox(
        width: width,
        child: button,
      );
    }
    
    return button;
  }
}

/// Enum untuk tipe button
enum ButtonType {
  primary,
  secondary,
  outline,
  text,
}

/// Enum untuk ukuran button
enum ButtonSize {
  small,
  medium,
  large,
}
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:klik_jasa/core/constants/app_colors.dart';

/// Widget TextFormField yang dapat digunakan kembali untuk mengurangi duplikasi kode
class CommonTextFormField extends StatelessWidget {
  final String? labelText;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String?)? onSaved;
  final void Function()? onTap;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final FocusNode? focusNode;
  final EdgeInsetsGeometry? contentPadding;
  final BorderRadius? borderRadius;

  const CommonTextFormField({
    super.key,
    this.labelText,
    this.hintText,
    this.helperText,
    this.errorText,
    this.controller,
    this.validator,
    this.onChanged,
    this.onSaved,
    this.onTap,
    this.keyboardType,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.prefixIcon,
    this.suffixIcon,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.focusNode,
    this.contentPadding,
    this.borderRadius,
  });

  /// Factory constructor untuk field email
  factory CommonTextFormField.email({
    String? labelText,
    String? hintText,
    TextEditingController? controller,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    bool enabled = true,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return CommonTextFormField(
      labelText: labelText ?? 'Email',
      hintText: hintText ?? 'Masukkan email Anda',
      controller: controller,
      validator: validator ?? _defaultEmailValidator,
      onChanged: onChanged,
      keyboardType: TextInputType.emailAddress,
      enabled: enabled,
      prefixIcon: prefixIcon ?? const Icon(Icons.email_outlined),
      suffixIcon: suffixIcon,
      textCapitalization: TextCapitalization.none,
    );
  }

  /// Factory constructor untuk field password
  factory CommonTextFormField.password({
    String? labelText,
    String? hintText,
    TextEditingController? controller,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    bool enabled = true,
    Widget? prefixIcon,
    Widget? suffixIcon,
    bool obscureText = true,
  }) {
    return CommonTextFormField(
      labelText: labelText ?? 'Password',
      hintText: hintText ?? 'Masukkan password Anda',
      controller: controller,
      validator: validator ?? _defaultPasswordValidator,
      onChanged: onChanged,
      obscureText: obscureText,
      enabled: enabled,
      prefixIcon: prefixIcon ?? const Icon(Icons.lock_outlined),
      suffixIcon: suffixIcon,
    );
  }

  /// Factory constructor untuk field phone
  factory CommonTextFormField.phone({
    String? labelText,
    String? hintText,
    TextEditingController? controller,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    bool enabled = true,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return CommonTextFormField(
      labelText: labelText ?? 'Nomor Telepon',
      hintText: hintText ?? 'Masukkan nomor telepon Anda',
      controller: controller,
      validator: validator ?? _defaultPhoneValidator,
      onChanged: onChanged,
      keyboardType: TextInputType.phone,
      enabled: enabled,
      prefixIcon: prefixIcon ?? const Icon(Icons.phone_outlined),
      suffixIcon: suffixIcon,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    );
  }

  /// Factory constructor untuk field search
  factory CommonTextFormField.search({
    String? hintText,
    TextEditingController? controller,
    void Function(String)? onChanged,
    void Function()? onTap,
    bool enabled = true,
    Widget? suffixIcon,
  }) {
    return CommonTextFormField(
      hintText: hintText ?? 'Cari...',
      controller: controller,
      onChanged: onChanged,
      onTap: onTap,
      enabled: enabled,
      prefixIcon: const Icon(Icons.search),
      suffixIcon: suffixIcon,
      borderRadius: BorderRadius.circular(25),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    );
  }

  /// Factory constructor untuk field multiline
  factory CommonTextFormField.multiline({
    String? labelText,
    String? hintText,
    TextEditingController? controller,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    bool enabled = true,
    int maxLines = 3,
    int? maxLength,
  }) {
    return CommonTextFormField(
      labelText: labelText,
      hintText: hintText,
      controller: controller,
      validator: validator,
      onChanged: onChanged,
      enabled: enabled,
      maxLines: maxLines,
      minLines: 2,
      maxLength: maxLength,
      textCapitalization: TextCapitalization.sentences,
    );
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      onChanged: onChanged,
      onSaved: onSaved,
      onTap: onTap,
      keyboardType: keyboardType,
      obscureText: obscureText,
      enabled: enabled,
      readOnly: readOnly,
      maxLines: maxLines,
      minLines: minLines,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      textCapitalization: textCapitalization,
      focusNode: focusNode,
      style: TextStyle(
        color: enabled ? AppColors.textPrimary : Colors.grey[600],
        fontSize: 16,
      ),
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        helperText: helperText,
        errorText: errorText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        contentPadding: contentPadding ??
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: borderRadius ?? BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: borderRadius ?? BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: borderRadius ?? BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: borderRadius ?? BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: borderRadius ?? BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: borderRadius ?? BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey[100],
        labelStyle: TextStyle(
          color: enabled ? AppColors.textSecondary : Colors.grey[500],
        ),
        hintStyle: TextStyle(
          color: Colors.grey[500],
        ),
      ),
    );
  }

  // Validator functions
  static String? _defaultEmailValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email tidak boleh kosong';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Format email tidak valid';
    }
    return null;
  }

  static String? _defaultPasswordValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password tidak boleh kosong';
    }
    if (value.length < 6) {
      return 'Password minimal 6 karakter';
    }
    return null;
  }

  static String? _defaultPhoneValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Nomor telepon tidak boleh kosong';
    }
    if (value.length < 10) {
      return 'Nomor telepon minimal 10 digit';
    }
    return null;
  }
}

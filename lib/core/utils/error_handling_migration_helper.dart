import 'package:flutter/material.dart';
import 'package:klik_jasa/features/common/utils/app_message_utils.dart';

/// Helper class untuk membantu migrasi dari ScaffoldMessenger langsung ke AppMessageUtils
/// yang konsisten di seluruh aplikasi
class ErrorHandlingMigrationHelper {
  /// Menggantikan ScaffoldMessenger.of(context).showSnackBar untuk error
  static void showError(BuildContext context, String message) {
    AppMessageUtils.showSnackbar(
      context: context,
      message: message,
      type: MessageType.error,
    );
  }

  /// Menggantikan ScaffoldMessenger.of(context).showSnackBar untuk success
  static void showSuccess(BuildContext context, String message) {
    AppMessageUtils.showSnackbar(
      context: context,
      message: message,
      type: MessageType.success,
    );
  }

  /// Menggantikan ScaffoldMessenger.of(context).showSnackBar untuk info
  static void showInfo(BuildContext context, String message) {
    AppMessageUtils.showSnackbar(
      context: context,
      message: message,
      type: MessageType.info,
    );
  }

  /// Menggantikan ScaffoldMessenger.of(context).showSnackBar untuk warning
  static void showWarning(BuildContext context, String message) {
    AppMessageUtils.showSnackbar(
      context: context,
      message: message,
      type: MessageType.warning,
    );
  }

  /// Helper untuk menampilkan dialog error yang user-friendly
  static void showErrorDialog(BuildContext context, String title, String message) {
    AppMessageUtils.showErrorDialog(
      context: context,
      title: title,
      message: message,
    );
  }

  /// Helper untuk menampilkan dialog konfirmasi
  static Future<bool> showConfirmDialog(
    BuildContext context,
    String title,
    String message, {
    String confirmText = 'Ya',
    String cancelText = 'Tidak',
  }) {
    return AppMessageUtils.showConfirmationDialog(
      context: context,
      title: title,
      message: message,
      confirmLabel: confirmText,
      cancelLabel: cancelText,
    );
  }

  /// Helper untuk menampilkan loading dialog
  static void showLoadingDialog(BuildContext context, String message) {
    AppMessageUtils.showLoadingDialog(
      context: context,
      message: message,
    );
  }

  /// Helper untuk menutup loading dialog
  static void hideLoadingDialog(BuildContext context) {
    AppMessageUtils.hideLoadingDialog(context);
  }

  /// Konversi exception ke pesan error yang user-friendly
  static String getErrorMessage(dynamic error) {
    if (error is Exception) {
      return _getExceptionMessage(error);
    } else if (error is String) {
      return error;
    } else {
      return 'Terjadi kesalahan yang tidak diketahui';
    }
  }

  /// Konversi exception ke pesan yang user-friendly
  static String _getExceptionMessage(Exception exception) {
    final message = exception.toString();
    
    // Network errors
    if (message.contains('SocketException') || 
        message.contains('NetworkException') ||
        message.contains('TimeoutException')) {
      return 'Koneksi internet bermasalah. Silakan coba lagi.';
    }
    
    // Authentication errors
    if (message.contains('AuthException') || 
        message.contains('Invalid login credentials')) {
      return 'Email atau password salah. Silakan coba lagi.';
    }
    
    // Permission errors
    if (message.contains('Permission denied') || 
        message.contains('Unauthorized')) {
      return 'Anda tidak memiliki izin untuk melakukan aksi ini.';
    }
    
    // Validation errors
    if (message.contains('Invalid email') || 
        message.contains('Email not valid')) {
      return 'Format email tidak valid.';
    }
    
    if (message.contains('Password too weak') || 
        message.contains('Password should be at least')) {
      return 'Password terlalu lemah. Minimal 6 karakter.';
    }
    
    // File upload errors
    if (message.contains('File too large') || 
        message.contains('Payload too large')) {
      return 'Ukuran file terlalu besar. Maksimal 5MB.';
    }
    
    // Database errors
    if (message.contains('PostgrestException') || 
        message.contains('duplicate key value')) {
      return 'Data sudah ada. Silakan gunakan data yang berbeda.';
    }
    
    // Default fallback
    return 'Terjadi kesalahan. Silakan coba lagi.';
  }

  /// Pattern untuk mencari dan mengganti ScaffoldMessenger usage
  static const List<String> deprecatedPatterns = [
    'ScaffoldMessenger.of(context).showSnackBar(',
    'ScaffoldMessenger.of(context).hideCurrentSnackBar(',
    'ScaffoldMessenger.of(context).removeCurrentSnackBar(',
  ];

  /// Replacement patterns menggunakan AppMessageUtils
  static const List<String> replacementPatterns = [
    'AppMessageUtils.showErrorSnackBar(context, ',
    'AppMessageUtils.hideCurrentSnackBar(context)',
    'AppMessageUtils.removeCurrentSnackBar(context)',
  ];

  /// Guide untuk migrasi manual
  static const String migrationGuide = '''
PANDUAN MIGRASI ERROR HANDLING:

1. Ganti ScaffoldMessenger.of(context).showSnackBar dengan:
   - AppMessageUtils.showErrorSnackBar(context, message) untuk error
   - AppMessageUtils.showSuccessSnackBar(context, message) untuk success
   - AppMessageUtils.showInfoSnackBar(context, message) untuk info
   - AppMessageUtils.showWarningSnackBar(context, message) untuk warning

2. Untuk dialog:
   - AppMessageUtils.showErrorDialog(context, title, message)
   - AppMessageUtils.showConfirmDialog(context, title, message)

3. Untuk loading:
   - AppMessageUtils.showLoadingDialog(context, message)
   - AppMessageUtils.hideLoadingDialog(context)

4. Gunakan ErrorHandlingMigrationHelper.getErrorMessage(error) 
   untuk konversi exception ke pesan user-friendly

5. Import yang diperlukan:
   import 'package:klik_jasa/core/utils/app_message_utils.dart';
   import 'package:klik_jasa/core/utils/error_handling_migration_helper.dart';
''';
}

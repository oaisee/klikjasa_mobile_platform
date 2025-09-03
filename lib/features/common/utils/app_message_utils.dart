import 'package:flutter/material.dart';

/// Enum untuk jenis pesan yang akan ditampilkan
enum MessageType { success, error, info, warning }

/// Kelas utilitas untuk menampilkan pesan ke pengguna secara konsisten
/// di seluruh aplikasi (snackbar, dialog, toast)
class AppMessageUtils {
  /// Menampilkan snackbar dengan gaya yang konsisten
  static void showSnackbar({
    required BuildContext context,
    required String message,
    MessageType type = MessageType.info,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    Color backgroundColor;
    Color textColor = Colors.white;
    IconData? icon;

    switch (type) {
      case MessageType.success:
        backgroundColor = Colors.green;
        icon = Icons.check_circle;
        break;
      case MessageType.error:
        backgroundColor = Colors.red;
        icon = Icons.error;
        break;
      case MessageType.warning:
        backgroundColor = Colors.orange;
        icon = Icons.warning;
        break;
      case MessageType.info:
        backgroundColor = Colors.blue;
        icon = Icons.info;
        break;
    }

    final snackBar = SnackBar(
      content: Row(
        children: [
          Icon(icon, color: textColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: textColor),
            ),
          ),
        ],
      ),
      backgroundColor: backgroundColor,
      duration: duration,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      margin: const EdgeInsets.all(8),
      action: onAction != null && actionLabel != null
          ? SnackBarAction(
              label: actionLabel,
              textColor: Colors.white,
              onPressed: onAction,
            )
          : null,
    );

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  /// Menampilkan dialog konfirmasi dengan gaya yang konsisten
  static Future<bool> showConfirmationDialog({
    required BuildContext context,
    required String title,
    required String message,
    String confirmLabel = 'Ya',
    String cancelLabel = 'Tidak',
    MessageType type = MessageType.info,
  }) async {
    Color iconColor;
    IconData icon;

    switch (type) {
      case MessageType.success:
        iconColor = Colors.green;
        icon = Icons.check_circle;
        break;
      case MessageType.error:
        iconColor = Colors.red;
        icon = Icons.error;
        break;
      case MessageType.warning:
        iconColor = Colors.orange;
        icon = Icons.warning;
        break;
      case MessageType.info:
        iconColor = Colors.blue;
        icon = Icons.info;
        break;
    }

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(icon, color: iconColor),
              const SizedBox(width: 10),
              Expanded(child: Text(title)),
            ],
          ),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(cancelLabel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: iconColor,
              ),
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  /// Menampilkan dialog error dengan gaya yang konsisten
  static Future<void> showErrorDialog({
    required BuildContext context,
    required String title,
    required String message,
    String buttonLabel = 'OK',
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.error, color: Colors.red),
              const SizedBox(width: 10),
              Expanded(child: Text(title)),
            ],
          ),
          content: Text(message),
          actions: <Widget>[
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: Text(buttonLabel),
            ),
          ],
        );
      },
    );
  }

  /// Menampilkan dialog informasi dengan gaya yang konsisten
  static Future<void> showInfoDialog({
    required BuildContext context,
    required String title,
    required String message,
    String buttonLabel = 'OK',
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.info, color: Colors.blue),
              const SizedBox(width: 10),
              Expanded(child: Text(title)),
            ],
          ),
          content: Text(message),
          actions: <Widget>[
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
              ),
              child: Text(buttonLabel),
            ),
          ],
        );
      },
    );
  }

  /// Menampilkan pesan error untuk form validation
  static void showFormValidationError({
    required BuildContext context,
    required String message,
  }) {
    showSnackbar(
      context: context,
      message: message,
      type: MessageType.error,
      duration: const Duration(seconds: 4),
    );
  }

  /// Menampilkan pesan error untuk network error
  static void showNetworkError({
    required BuildContext context,
    required String message,
    VoidCallback? onRetry,
  }) {
    showSnackbar(
      context: context,
      message: message,
      type: MessageType.error,
      duration: const Duration(seconds: 5),
      onAction: onRetry,
      actionLabel: onRetry != null ? 'Coba Lagi' : null,
    );
  }

  /// Menampilkan pesan sukses
  static void showSuccess({
    required BuildContext context,
    required String message,
  }) {
    showSnackbar(
      context: context,
      message: message,
      type: MessageType.success,
    );
  }

  /// Menampilkan pesan warning
  static void showWarning({
    required BuildContext context,
    required String message,
  }) {
    showSnackbar(
      context: context,
      message: message,
      type: MessageType.warning,
    );
  }

  /// Menampilkan loading dialog
  static void showLoadingDialog({
    required BuildContext context,
    String message = 'Memuat...',
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 20),
              Expanded(
                child: Text(message),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Menyembunyikan loading dialog
  static void hideLoadingDialog(BuildContext context) {
    Navigator.of(context).pop();
  }
}

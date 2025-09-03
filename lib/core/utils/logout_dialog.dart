import 'package:flutter/material.dart';
import 'package:klik_jasa/core/constants/app_strings.dart';
import 'package:klik_jasa/core/constants/app_colors.dart';

/// Dialog konfirmasi untuk logout dari aplikasi
/// 
/// Menampilkan dialog konfirmasi dengan dua opsi: batal dan logout
/// Mengembalikan `true` jika pengguna memilih logout, `false` jika batal
Future<bool> showLogoutDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text(AppStrings.konfirmasiLogout),
        content: const Text(AppStrings.yakinInginKeluar),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              AppStrings.batal,
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text(AppStrings.logout),
          ),
        ],
      );
    },
  );

  // Jika result null (dialog ditutup dengan cara lain), anggap sebagai batal
  return result ?? false;
}
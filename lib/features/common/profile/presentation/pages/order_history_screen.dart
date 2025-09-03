import 'package:flutter/material.dart';
import 'package:klik_jasa/core/constants/app_strings.dart';

class OrderHistoryScreen extends StatelessWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.riwayatPesanan),
      ),
      body: Center(
        child: Text('${AppStrings.riwayatPesanan} ${AppStrings.segeraHadir}'),
      ),
    );
  }
}

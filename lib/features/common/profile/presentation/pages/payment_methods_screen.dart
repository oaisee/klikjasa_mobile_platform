import 'package:flutter/material.dart';
import 'package:klik_jasa/core/constants/app_strings.dart';

class PaymentMethodsScreen extends StatelessWidget {
  const PaymentMethodsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.metodePembayaran),
      ),
      body: Center(
        child: Text('${AppStrings.metodePembayaran} ${AppStrings.segeraHadir}'),
      ),
    );
  }
}

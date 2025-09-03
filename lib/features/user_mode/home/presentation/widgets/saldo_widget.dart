import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:klik_jasa/features/common/profile/application/bloc/user_view_bloc.dart';

class SaldoWidget extends StatelessWidget {
  const SaldoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserViewBloc, UserViewState>(
      buildWhen: (previous, current) =>
          previous.isLoading != current.isLoading || previous.saldo != current.saldo,
      builder: (context, state) {
        Widget content;

        if (state.isLoading && state.saldo == 0.0) {
          content = const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          );
        } else {
          final formattedBalance = NumberFormat.currency(
            locale: 'id_ID',
            symbol: 'Rp ',
            decimalDigits: 0,
          ).format(state.saldo);
          content = Text(
            formattedBalance,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          );
        }

        return InkWell(
          onTap: () => context.push('/topup'),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.account_balance_wallet, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: content,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

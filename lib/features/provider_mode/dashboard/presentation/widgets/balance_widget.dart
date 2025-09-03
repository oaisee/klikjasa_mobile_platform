import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:klik_jasa/features/common/auth/application/bloc/auth_bloc.dart';
import 'package:klik_jasa/features/common/profile/application/bloc/user_view_bloc.dart';

/// A widget that displays the user's balance.
/// 
/// This widget shows the current balance and allows navigation to the top-up screen
/// when tapped. It also refreshes the balance automatically when displayed.
class BalanceWidget extends StatefulWidget {
  const BalanceWidget({super.key});

  @override
  State<BalanceWidget> createState() => _BalanceWidgetState();
}

class _BalanceWidgetState extends State<BalanceWidget> {
  @override
  void initState() {
    super.initState();
    // Refresh saldo saat widget pertama kali dibuat
    _refreshBalance();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh saldo saat dependencies berubah (misalnya saat navigasi)
    _refreshBalance();
  }

  void _refreshBalance() {
    // Ambil userId dari AuthBloc
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      // Perbarui saldo secara real-time
      context.read<UserViewBloc>().refreshBalance(authState.user.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocSelector<UserViewBloc, UserViewState, double?>(
      selector: (state) => state.saldo,
      builder: (context, saldo) {
        final bool isLoading = saldo == null;

        final Widget content = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.account_balance_wallet_outlined,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    NumberFormat.currency(
                      locale: 'id_ID',
                      symbol: 'Rp ',
                      decimalDigits: 0,
                    ).format(saldo).replaceAll(',', '.'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ],
        );

        return InkWell(
          onTap: () {
            // Refresh saldo sebelum navigasi ke halaman top-up
            _refreshBalance();
            context.pushNamed('topUp');
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
            child: content,
          ),
        );
      },
    );
  }
}
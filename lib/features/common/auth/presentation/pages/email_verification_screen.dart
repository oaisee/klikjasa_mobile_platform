import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';

import '../../../../../routes/app_router.dart';
import '../../application/bloc/auth_bloc.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;

  const EmailVerificationScreen({
    super.key,
    required this.email,
  });

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final Logger _logger = Logger();
  bool _canResend = true;
  int _resendCooldown = 0;

  void _startResendCooldown() {
    setState(() {
      _canResend = false;
      _resendCooldown = 60;
    });

    // Countdown timer
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() {
          _resendCooldown--;
        });
        if (_resendCooldown <= 0) {
          setState(() {
            _canResend = true;
          });
          return false;
        }
      }
      return _resendCooldown > 0 && mounted;
    });
  }

  void _resendEmail() {
    if (_canResend) {
      context.read<AuthBloc>().add(
            AuthEmailConfirmationResendRequested(
              email: widget.email,
            ),
          );
      _startResendCooldown();
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => GoRouter.of(context).go(AppRouter.loginRoute),
        ),
        title: const Text(
          'Verifikasi Email',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthEmailConfirmationResendSuccess) {
            _logger.i(
              'EMAIL VERIFICATION SCREEN: AuthEmailConfirmationResendSuccess - Pesan: ${state.message}',
            );
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.green,
                ),
              );
          } else if (state is AuthEmailConfirmationResendFailure) {
            _logger.e(
              'EMAIL VERIFICATION SCREEN: AuthEmailConfirmationResendFailure - Pesan: ${state.message}',
            );
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text('Gagal mengirim ulang email: ${state.message}'),
                  backgroundColor: Colors.red,
                ),
              );
          } else if (state is AuthAuthenticated) {
            _logger.i(
              'EMAIL VERIFICATION SCREEN: AuthAuthenticated - User: ${state.user.email}',
            );
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                const SnackBar(
                  content: Text(
                      'Email berhasil diverifikasi! Selamat datang di KlikJasa.'),
                  backgroundColor: Colors.green,
                ),
              );
            // Navigasi ke home setelah verifikasi berhasil
            GoRouter.of(context).go(AppRouter.homeRoute);
          }
        },
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Icon email
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.email_outlined,
                          size: 60,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Title
                      const Text(
                        'Verifikasi Email Anda',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),

                      // Description
                      Text(
                        'Kami telah mengirimkan email verifikasi ke:',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),

                      // Email address
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Text(
                          widget.email,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Instructions
                      Text(
                        'Silakan periksa kotak masuk email Anda dan klik tautan verifikasi untuk mengaktifkan akun Anda.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),

                      // Resend button
                      BlocBuilder<AuthBloc, AuthState>(
                        builder: (context, state) {
                          final isLoading =
                              state is AuthEmailConfirmationResendLoading;

                          return SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _canResend && !isLoading
                                    ? primaryColor
                                    : Colors.grey[400],
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onPressed: (_canResend && !isLoading)
                                  ? _resendEmail
                                  : null,
                              child: isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      _canResend
                                          ? 'Kirim Ulang Email'
                                          : 'Kirim Ulang ($_resendCooldown detik)',
                                    ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      // Help text
                      Text(
                        'Tidak menerima email? Periksa folder spam atau coba kirim ulang.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                // Back to login button
                TextButton(
                  onPressed: () =>
                      GoRouter.of(context).go(AppRouter.loginRoute),
                  child: Text(
                    'Kembali ke Login',
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

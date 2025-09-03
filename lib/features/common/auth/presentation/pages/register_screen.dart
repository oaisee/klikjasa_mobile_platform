import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';
import 'package:klik_jasa/core/constants/app_strings.dart';
import 'package:klik_jasa/routes/app_router.dart';
import 'package:klik_jasa/features/common/auth/application/bloc/auth_bloc.dart';
import 'dart:io' show Platform;

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final Logger _logger = Logger();
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _register() {
    if (_formKey.currentState!.validate()) {
      if (_passwordController.text != _confirmPasswordController.text) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(AppStrings.passwordsDoNotMatch)),
          );
        }
        return;
      }
      // TODO: Pastikan AuthBloc dan AuthRegisterRequested mendukung field fullName
      // final String fullName = _fullNameController.text.trim();
      final String fullName = _fullNameController.text.trim();
      context.read<AuthBloc>().add(
        AuthRegisterRequested(
          fullName: fullName,
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthRegistrationSuccess) {
              _logger.i(
                'REGISTER SCREEN LISTENER: AuthRegistrationSuccess - Pesan: ${state.message}',
              );
              final email = _emailController.text.trim();
              context.pushNamed(
                'emailVerification',
                queryParameters: {'email': email},
              );
            } else if (state is AuthEmailConfirmationResendSuccess) {
              _logger.i(
                'REGISTER SCREEN LISTENER: AuthEmailConfirmationResendSuccess - Pesan: ${state.message}',
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
                'REGISTER SCREEN LISTENER: AuthEmailConfirmationResendFailure - Pesan: ${state.message}',
              );
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text('Gagal mengirim ulang email: ${state.message}'),
                    backgroundColor: Colors.red,
                  ),
                );
            } else if (state is AuthFailure) {
              _logger.e(
                'REGISTER SCREEN LISTENER: AuthFailure - Pesan: ${state.message}',
              );
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text('Proses registrasi gagal: ${state.message}'),
                    backgroundColor: Colors.red,
                  ),
                );
            } else if (state is AuthAuthenticated) {
              _logger.i(
                'REGISTER SCREEN LISTENER: AuthAuthenticated - User: ${state.user.email}',
              );
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Berhasil! Selamat bergabung di marketplace KlikJasa...',
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              // Selalu arahkan ke halaman login setelah registrasi berhasil
              GoRouter.of(context).go(AppRouter.loginRoute);
            }
          },
          builder: (context, state) {
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 32.0,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24.0),
                          child: Image.asset(
                            'assets/logo/logo.png',
                            height: 80,
                            semanticLabel: 'Logo KlikJasa',
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          AppStrings.buatAkunBaru,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppStrings.isiDataUntukDaftar,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey[700]),
                        ),
                        const SizedBox(height: 32),
                        TextFormField(
                          controller: _fullNameController,
                          decoration: InputDecoration(
                            labelText: AppStrings.namaLengkap,
                            prefixIcon: const Icon(Icons.person_outline),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          keyboardType: TextInputType.name,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Nama lengkap tidak boleh kosong';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: AppStrings.email,
                            prefixIcon: const Icon(Icons.email_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Email tidak boleh kosong';
                            }
                            if (!value.contains('@') || !value.contains('.')) {
                              return 'Masukkan alamat email yang valid';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: AppStrings.password,
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.grey[600],
                              ),
                              onPressed: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          obscureText: !_isPasswordVisible,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Kata sandi tidak boleh kosong';
                            }
                            if (value.length < 6) {
                              return 'Kata sandi minimal 6 karakter';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _confirmPasswordController,
                          decoration: InputDecoration(
                            labelText: AppStrings.konfirmasiPassword,
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isConfirmPasswordVisible
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.grey[600],
                              ),
                              onPressed: () {
                                setState(() {
                                  _isConfirmPasswordVisible =
                                      !_isConfirmPasswordVisible;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          obscureText: !_isConfirmPasswordVisible,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Konfirmasi kata sandi tidak boleh kosong';
                            }
                            if (value != _passwordController.text) {
                              return 'Kata sandi tidak cocok';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onPressed: (state is AuthLoading || state is AuthEmailConfirmationResendLoading) ? null : _register,
                          child: (state is AuthLoading || state is AuthEmailConfirmationResendLoading)
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(AppStrings.daftar),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            const Text(AppStrings.sudahPunyaAkun),
                            TextButton(
                              onPressed: () {
                                if (GoRouter.of(context).canPop()) {
                                  GoRouter.of(context).pop();
                                } else {
                                  GoRouter.of(context).go(AppRouter.loginRoute);
                                }
                              },
                              child: Text(
                                AppStrings.login,
                                style: TextStyle(
                                  color: primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildSocialLoginDivider(),
                        const SizedBox(height: 16),
                        _buildSocialLoginButtons(),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // Widget untuk divider login sosial
  Widget _buildSocialLoginDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(right: 10.0),
            height: 1.0,
            color: Colors.grey[300],
          ),
        ),
        Text(
          'Atau daftar dengan',
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(left: 10.0),
            height: 1.0,
            color: Colors.grey[300],
          ),
        ),
      ],
    );
  }

  // Widget untuk tombol login sosial
  Widget _buildSocialLoginButtons() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Tombol Google
            _buildSocialButton(
              onPressed: () {
                context.read<AuthBloc>().add(const AuthGoogleSignInRequested());
              },
              iconPath: 'assets/icons/google_icon.png',
              label: 'Google',
              backgroundColor: Colors.white,
              textColor: Colors.black87,
            ),
            const SizedBox(width: 16),
            // Tombol Apple (hanya ditampilkan di iOS)
            if (Platform.isIOS)
              _buildSocialButton(
                onPressed: () {
                  context.read<AuthBloc>().add(const AuthAppleSignInRequested());
                },
                iconPath: 'assets/icons/apple_icon.png',
                label: 'Apple',
                backgroundColor: Colors.black,
                textColor: Colors.white,
              ),
          ],
        ),
        const SizedBox(height: 16),

      ],
    );
  }

  // Widget untuk tombol login sosial
  Widget _buildSocialButton({
    required VoidCallback onPressed,
    required String iconPath,
    required String label,
    required Color backgroundColor,
    required Color textColor,
  }) {
    return Expanded(
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Image.asset(
          iconPath,
          height: 24,
          width: 24,
        ),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey[300]!),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}

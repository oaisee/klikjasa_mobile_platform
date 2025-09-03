import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:klik_jasa/core/constants/app_strings.dart';
import 'package:klik_jasa/routes/app_router.dart';
import 'package:klik_jasa/features/common/auth/application/bloc/auth_bloc.dart';
import 'package:klik_jasa/features/common/auth/data/services/biometric_auth_service.dart';
import 'dart:io' show Platform;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  final BiometricAuthService _biometricService = BiometricAuthService();
  bool _isBiometricAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
  }

  Future<void> _checkBiometricAvailability() async {
    final isAvailable = await _biometricService.isBiometricAvailable();
    final isEnabled = await _biometricService.isBiometricEnabled();

    if (mounted) {
      setState(() {
        _isBiometricAvailable = isAvailable && isEnabled;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() {
    final bool isValid = _formKey.currentState!.validate();

    if (isValid) {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      // Selalu gunakan AuthBloc untuk autentikasi, termasuk untuk admin
      // agar JWT valid tersedia untuk pemanggilan fungsi server
      context.read<AuthBloc>().add(
        AuthLoginRequested(email: email, password: password),
      );

      // Tampilkan pesan sukses khusus untuk admin setelah autentikasi berhasil
      // Pesan akan ditampilkan di listener BlocConsumer
    }
  }

  Future<void> _loginWithBiometric() async {
    final userId = await _biometricService.getBiometricUserId();

    if (userId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Anda belum mengaktifkan login biometrik. Silakan login dengan email dan password terlebih dahulu.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final bool authenticated = await _biometricService.authenticate(
      localizedReason: 'Autentikasi dengan sidik jari atau wajah untuk masuk',
    );

    if (authenticated && mounted) {
      // Trigger login event dengan userId yang tersimpan
      context.read<AuthBloc>().add(AuthBiometricLoginRequested(userId: userId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(
      context,
    ).primaryColor; // Asumsi warna primer dari tema
    // Atau definisikan warna primer kustom di sini, contoh:
    // final Color primaryColor = Colors.teal;

    return Scaffold(
      backgroundColor: Colors.grey[100], // Latar belakang netral terang
      body: SafeArea(
        child: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthFailure) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(
                      state.message.contains('kredensial') ||
                              state.message.contains('Kredensial')
                          ? 'Email atau kata sandi yang Anda masukkan salah. Silakan periksa kembali.'
                          : state.message,
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
            } else if (state is AuthAuthenticated) {
              ScaffoldMessenger.of(
                context,
              ).hideCurrentSnackBar(); // Sembunyikan snackbar sebelumnya

              // Cek apakah user adalah admin berdasarkan role di profile
              if (state.user.role == 'admin' ||
                  state.user.email == 'admin@klikjasa.com') {
                // Navigasi langsung ke dasbor admin
                GoRouter.of(context).go(AppRouter.adminBaseRoute);

                // Tampilkan pesan sukses untuk admin
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Berhasil masuk sebagai admin!'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ),
                );
              } else {
                GoRouter.of(context).go(AppRouter.homeRoute);
              }
              // Tampilkan pesan sukses singkat setelah navigasi (opsional, bisa dihapus jika tidak diinginkan)
              // ScaffoldMessenger.of(context).showSnackBar(
              //   SnackBar(
              //     content: Text('Berhasil masuk sebagai ${state.role ?? 'pengguna'}!'),
              //     backgroundColor: Colors.green,
              //     duration: const Duration(seconds: 2),
              //   ),
              // );
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
                  constraints: const BoxConstraints(
                    maxWidth: 400,
                  ), // Batasi lebar form di layar besar
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24.0),
                          child: Image.asset(
                            'assets/logo/logo.png',
                            height: 100, // Sesuaikan tinggi logo jika perlu
                            semanticLabel: 'Logo KlikJasa',
                          ),
                        ),
                        const SizedBox(height: 12), // Tambahan spasi jika perlu
                        Text(
                          AppStrings
                              .selamatDatangKembali, // Pastikan string ini ada di AppStrings
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppStrings
                              .masukUntukMelanjutkan, // Pastikan string ini ada di AppStrings
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 25),

                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            hintText: AppStrings.email,
                            prefixIcon: Icon(
                              Icons.email_outlined,
                              color: primaryColor,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 16,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: primaryColor,
                                width: 2,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
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
                            hintText: AppStrings.password,
                            prefixIcon: Icon(
                              Icons.lock_outline,
                              color: primaryColor,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible
                                    ? Icons.visibility_off
                                    : Icons.visibility,
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
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 16,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: primaryColor,
                                width: 2,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
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
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              GoRouter.of(context).push('/reset-password');
                            },
                            child: Text(
                              AppStrings.lupaPassword,
                              style: TextStyle(color: primaryColor),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
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
                          onPressed: state is AuthLoading ? null : _login,
                          child: state is AuthLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(AppStrings.login),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            const Text(AppStrings.belumPunyaAkun),
                            TextButton(
                              onPressed: () {
                                GoRouter.of(
                                  context,
                                ).push(AppRouter.registerRoute);
                              },
                              child: Text(
                                AppStrings.daftar,
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
                      ], // End of Column children
                    ), // Closes Column
                  ), // Closes Form
                ), // Closes ConstrainedBox
              ), // Closes SingleChildScrollView
            ); // Closes Center & return statement for builder
          }, // Closes builder block
        ), // Closes BlocConsumer
      ), // Closes SafeArea
    ); // Closes Scaffold & return statement for build method
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
          'Atau masuk dengan',
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
    return Row(
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
        // Tombol Biometrik (hanya ditampilkan jika tersedia dan diaktifkan)
        if (_isBiometricAvailable) const SizedBox(width: 16),
        if (_isBiometricAvailable)
          _buildSocialButton(
            onPressed: _loginWithBiometric,
            iconData: Icons.fingerprint,
            label: 'Biometrik',
            backgroundColor: Colors.teal,
            textColor: Colors.white,
          ),
      ],
    );
  }

  // Widget untuk tombol login sosial
  Widget _buildSocialButton({
    required VoidCallback onPressed,
    String? iconPath,
    IconData? iconData,
    required String label,
    required Color backgroundColor,
    required Color textColor,
  }) {
    return Expanded(
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: iconPath != null
            ? Image.asset(iconPath, height: 24, width: 24)
            : Icon(iconData ?? Icons.login, size: 24, color: textColor),
        label: Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 14),
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
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

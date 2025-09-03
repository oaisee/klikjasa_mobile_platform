import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klik_jasa/core/constants/app_colors.dart';
import 'package:klik_jasa/core/constants/app_strings.dart';
import 'package:klik_jasa/features/common/theme/application/theme_bloc.dart';
import 'package:klik_jasa/features/common/auth/application/bloc/auth_bloc.dart';
// import yang tidak digunakan dihapus
import 'package:klik_jasa/features/common/utils/app_message_utils.dart';
import '../cubit/settings_cubit.dart';
import '../cubit/settings_state.dart';

/// Halaman pengaturan aplikasi yang menggunakan Cubit
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SettingsCubit()
        ..loadSettings()
        ..loadAppVersion()
        ..checkBiometricAvailability(),
      child: const _SettingsView(),
    );
  }
}

class _SettingsView extends StatelessWidget {
  const _SettingsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          AppStrings.settings,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: BlocListener<SettingsCubit, SettingsState>(
        listener: (context, state) {
          if (state.errorMessage != null) {
            AppMessageUtils.showSnackbar(
              context: context,
              message: state.errorMessage!,
              type: MessageType.error,
            );
            context.read<SettingsCubit>().clearError();
          }
          
          if (state.isSuccess) {
            AppMessageUtils.showSnackbar(
              context: context,
              message: 'Pengaturan berhasil disimpan',
              type: MessageType.success,
            );
            context.read<SettingsCubit>().clearSuccess();
          }
        },
        child: BlocBuilder<SettingsCubit, SettingsState>(
          builder: (context, state) {
            if (state.isLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildNotificationSection(context, state),
                  const SizedBox(height: 24),
                  _buildLanguageSection(context, state),
                  const SizedBox(height: 24),
                  _buildSecuritySection(context, state),
                  const SizedBox(height: 24),
                  _buildThemeSection(context),
                  const SizedBox(height: 24),
                  _buildAppInfoSection(context, state),
                  const SizedBox(height: 24),
                  _buildAccountSection(context),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildNotificationSection(BuildContext context, SettingsState state) {
    return _buildSection(
      title: 'Notifikasi',
      children: [
        _buildSwitchTile(
          title: 'Notifikasi Umum',
          subtitle: 'Terima notifikasi dari aplikasi',
          value: state.notificationsEnabled,
          onChanged: (value) {
            context.read<SettingsCubit>().toggleNotifications(value);
          },
        ),
        _buildSwitchTile(
          title: 'Email Notifikasi',
          subtitle: 'Terima notifikasi melalui email',
          value: state.emailNotifications,
          onChanged: (value) {
            context.read<SettingsCubit>().toggleEmailNotifications(value);
          },
        ),
        _buildSwitchTile(
          title: 'Push Notifikasi',
          subtitle: 'Terima push notification',
          value: state.pushNotifications,
          onChanged: (value) {
            context.read<SettingsCubit>().togglePushNotifications(value);
          },
        ),
      ],
    );
  }

  Widget _buildLanguageSection(BuildContext context, SettingsState state) {
    return _buildSection(
      title: 'Bahasa',
      children: [
        _buildListTile(
          title: 'Bahasa Aplikasi',
          subtitle: state.selectedLanguage,
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () => _showLanguageDialog(context, state),
        ),
      ],
    );
  }

  Widget _buildSecuritySection(BuildContext context, SettingsState state) {
    return _buildSection(
      title: 'Keamanan',
      children: [
        if (state.isBiometricAvailable)
          _buildSwitchTile(
            title: 'Autentikasi Biometrik',
            subtitle: 'Gunakan sidik jari atau face ID',
            value: state.biometricEnabled,
            onChanged: (value) {
              context.read<SettingsCubit>().toggleBiometric(value);
            },
          ),
        _buildSwitchTile(
          title: 'Two-Factor Authentication',
          subtitle: 'Keamanan tambahan untuk akun',
          value: state.twoFactorEnabled,
          onChanged: (value) {
            context.read<SettingsCubit>().toggleTwoFactor(value);
          },
        ),
      ],
    );
  }

  Widget _buildThemeSection(BuildContext context) {
    return _buildSection(
      title: 'Tampilan',
      children: [
        BlocBuilder<ThemeBloc, ThemeState>(
          builder: (context, themeState) {
            return _buildSwitchTile(
              title: 'Mode Gelap',
              subtitle: 'Gunakan tema gelap',
              value: themeState.themeMode == AppThemeMode.dark,
              onChanged: (value) {
                context.read<ThemeBloc>().add(ThemeChanged(isDarkMode: value));
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildAppInfoSection(BuildContext context, SettingsState state) {
    return _buildSection(
      title: 'Informasi Aplikasi',
      children: [
        _buildListTile(
          title: 'Versi Aplikasi',
          subtitle: state.appVersion,
        ),
        _buildListTile(
          title: 'Tentang Aplikasi',
          subtitle: 'Informasi lebih lanjut',
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () => _showAboutDialog(context),
        ),
        _buildListTile(
          title: 'Kebijakan Privasi',
          subtitle: 'Baca kebijakan privasi',
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () => _showPrivacyPolicy(context),
        ),
        _buildListTile(
          title: 'Syarat dan Ketentuan',
          subtitle: 'Baca syarat dan ketentuan',
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () => _showTermsOfService(context),
        ),
      ],
    );
  }

  Widget _buildAccountSection(BuildContext context) {
    return _buildSection(
      title: 'Akun',
      children: [
        _buildListTile(
          title: 'Keluar',
          subtitle: 'Keluar dari akun',
          titleColor: Colors.red,
          trailing: const Icon(Icons.logout, color: Colors.red),
          onTap: () => _showLogoutDialog(context),
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 14,
        ),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.primary,
    );
  }

  Widget _buildListTile({
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    Color? titleColor,
  }) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 16,
          color: titleColor,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 14,
        ),
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }

  void _showLanguageDialog(BuildContext context, SettingsState state) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pilih Bahasa'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Bahasa Indonesia'),
              value: 'Bahasa Indonesia',
              groupValue: state.selectedLanguage,
              onChanged: (value) {
                if (value != null) {
                  context.read<SettingsCubit>().changeLanguage(value);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<String>(
              title: const Text('English'),
              value: 'English',
              groupValue: state.selectedLanguage,
              onChanged: (value) {
                if (value != null) {
                  context.read<SettingsCubit>().changeLanguage(value);
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'KlikJasa',
      applicationVersion: '1.0.0',
      applicationLegalese: '© 2024 KlikJasa. All rights reserved.',
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 16),
          child: Text(
            'KlikJasa adalah platform yang menghubungkan penyedia jasa dengan pengguna yang membutuhkan berbagai layanan.',
          ),
        ),
      ],
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    AppMessageUtils.showSnackbar(
      context: context,
      message: 'Kebijakan privasi akan ditampilkan di sini',
      type: MessageType.info,
    );
  }

  void _showTermsOfService(BuildContext context) {
    AppMessageUtils.showSnackbar(
      context: context,
      message: 'Syarat dan ketentuan akan ditampilkan di sini',
      type: MessageType.info,
    );
  }

  void _showLogoutDialog(BuildContext context) {
    // Simpan referensi ke AuthBloc sebelum operasi asynchronous
    final authBloc = context.read<AuthBloc>();
    
    AppMessageUtils.showConfirmationDialog(
      context: context,
      title: 'Keluar',
      message: 'Apakah Anda yakin ingin keluar dari aplikasi?',
      confirmLabel: 'Ya, Keluar',
      cancelLabel: 'Batal',
      type: MessageType.warning,
    ).then((confirmed) {
      if (confirmed) {
        // Gunakan authBloc yang sudah disimpan
        authBloc.add(AuthLogoutRequested());
      }
    });
  }
}

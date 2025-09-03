import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:klik_jasa/features/admin_mode/presentation/bloc/app_settings/app_settings_bloc.dart';
import 'package:klik_jasa/features/admin_mode/presentation/bloc/app_settings/app_settings_event.dart';
import 'package:klik_jasa/features/admin_mode/presentation/bloc/app_settings/app_settings_state.dart';
import 'package:klik_jasa/features/common/app_config/domain/entities/app_config.dart';

class AppSettingsScreen extends StatefulWidget {
  const AppSettingsScreen({super.key});

  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    context.read<AppSettingsBloc>().add(GetAllAppSettingsEvent());
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _controllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<AppSettingsBloc, AppSettingsState>(
        listener: (context, state) {
          if (state is AppSettingUpdated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Pengaturan berhasil disimpan'),
                backgroundColor: Colors.green,
              ),
            );
            // Refresh data setelah update
            context.read<AppSettingsBloc>().add(GetAllAppSettingsEvent());
          } else if (state is AppSettingsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is AppSettingsLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is AppSettingsLoaded) {
            _initializeControllers(state.settings);
            return _buildSettingsUI(state.settings);
          } else if (state is AppSettingsError) {
            return Center(child: Text(state.message));
          }
          
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
  
  void _initializeControllers(List<AppConfig> settings) {
    for (var setting in settings) {
      if (!_controllers.containsKey(setting.key)) {
        _controllers[setting.key] = TextEditingController(text: setting.value);
      } else if (_controllers[setting.key]!.text.isEmpty) {
        _controllers[setting.key]!.text = setting.value;
      }
    }
  }
  
  Widget _buildSettingsUI(List<AppConfig> settings) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Pengguna & Penyedia'),
            Tab(text: 'Notifikasi'),
            Tab(text: 'Keamanan'),
            Tab(text: 'Konten & Tampilan'),
            Tab(text: 'Analitik & Laporan'),
          ],
        ),
        Expanded(
          child: Form(
            key: _formKey,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildUserProviderSettings(settings),
                _buildNotificationSettings(settings),
                _buildSecuritySettings(settings),
                _buildContentSettings(settings),
                _buildAnalyticsSettings(settings),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildUserProviderSettings(List<AppConfig> settings) {
    // Filter pengaturan yang termasuk dalam kategori ini
    // Menggunakan filter untuk memudahkan pengembangan di masa depan
    // jika ingin menampilkan pengaturan secara dinamis
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCategoryHeader('Pengaturan Pengguna & Penyedia Jasa'),
          const SizedBox(height: 16),
          _buildSettingCard(
            title: 'Persyaratan Verifikasi Penyedia Jasa',
            description: 'Kriteria verifikasi penyedia jasa yang dapat diubah sewaktu-waktu',
            settingKey: 'provider_verification_requirements',
            isMultiline: true,
          ),
          const SizedBox(height: 16),
          _buildSettingCard(
            title: 'Batas Minimal Top-Up',
            description: 'Jumlah minimal top-up untuk pengguna (dalam Rupiah)',
            settingKey: 'min_topup_amount',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          _buildSettingCard(
            title: 'Biaya Aplikasi untuk Pengguna',
            description: 'Persentase biaya aplikasi yang dikenakan pada pengguna saat checkout',
            settingKey: 'user_fee_percentage',
            keyboardType: TextInputType.number,
            suffix: '%',
          ),
          const SizedBox(height: 16),
          _buildSettingCard(
            title: 'Biaya Aplikasi untuk Penyedia Jasa',
            description: 'Persentase biaya aplikasi yang dikenakan pada penyedia jasa saat mengkonfirmasi order masuk',
            settingKey: 'provider_fee_percentage',
            keyboardType: TextInputType.number,
            suffix: '%',
          ),
          const SizedBox(height: 40),
          _buildSaveButton(),
        ],
      ),
    );
  }
  
  Widget _buildNotificationSettings(List<AppConfig> settings) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCategoryHeader('Pengaturan Notifikasi & Komunikasi'),
          const SizedBox(height: 16),
          _buildSettingCard(
            title: 'Template Notifikasi - Order Baru',
            description: 'Template pesan untuk notifikasi order baru',
            settingKey: 'notification_template_new_order',
            isMultiline: true,
          ),
          const SizedBox(height: 16),
          _buildSettingCard(
            title: 'Template Notifikasi - Order Selesai',
            description: 'Template pesan untuk notifikasi order selesai',
            settingKey: 'notification_template_completed_order',
            isMultiline: true,
          ),
          const SizedBox(height: 16),
          _buildSettingCard(
            title: 'Frekuensi Notifikasi Promosi',
            description: 'Jumlah maksimal notifikasi promosi per minggu',
            settingKey: 'promo_notification_frequency',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          _buildSettingCard(
            title: 'Durasi Penyimpanan Chat',
            description: 'Berapa lama histori chat disimpan setelah pesanan selesai (dalam hari)',
            settingKey: 'chat_retention_days',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          _buildSettingCard(
            title: 'Notifikasi Wajib',
            description: 'Jenis notifikasi yang tidak dapat dinonaktifkan oleh pengguna (pisahkan dengan koma)',
            settingKey: 'mandatory_notifications',
          ),
          const SizedBox(height: 16),
          _buildSettingCard(
            title: 'Pengingat Otomatis',
            description: 'Interval pengingat otomatis untuk pesanan yang belum selesai (dalam jam)',
            settingKey: 'order_reminder_interval',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 40),
          _buildSaveButton(),
        ],
      ),
    );
  }
  
  Widget _buildSecuritySettings(List<AppConfig> settings) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCategoryHeader('Pengaturan Keamanan & Privasi'),
          const SizedBox(height: 16),
          _buildSettingCard(
            title: 'Masa Berlaku OTP',
            description: 'Durasi kode OTP untuk verifikasi (dalam menit)',
            settingKey: 'otp_expiry_minutes',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          _buildSettingCard(
            title: 'Batas Percobaan Login',
            description: 'Jumlah maksimal percobaan login sebelum akun dikunci',
            settingKey: 'max_login_attempts',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          _buildSettingCard(
            title: 'Durasi Sesi',
            description: 'Berapa lama sesi login aktif sebelum logout otomatis (dalam menit)',
            settingKey: 'session_timeout_minutes',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          _buildSettingCard(
            title: 'Kebijakan Kata Sandi',
            description: 'Persyaratan kompleksitas kata sandi (min. panjang, karakter khusus, dll)',
            settingKey: 'password_policy',
            isMultiline: true,
          ),
          const SizedBox(height: 16),
          _buildSettingCard(
            title: 'Verifikasi Dua Faktor',
            description: 'Status penggunaan verifikasi dua faktor (true/false)',
            settingKey: 'two_factor_auth_enabled',
          ),
          const SizedBox(height: 40),
          _buildSaveButton(),
        ],
      ),
    );
  }
  
  Widget _buildContentSettings(List<AppConfig> settings) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCategoryHeader('Pengaturan Konten & Tampilan'),
          const SizedBox(height: 16),
          _buildSettingCard(
            title: 'Durasi Banner Promosi',
            description: 'Durasi tampilan banner promosi di beranda (dalam hari)',
            settingKey: 'promo_banner_duration_days',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          _buildSettingCard(
            title: 'Pengumuman Sistem',
            description: 'Pengumuman penting untuk semua pengguna',
            settingKey: 'system_announcement',
            isMultiline: true,
          ),
          const SizedBox(height: 16),
          _buildSettingCard(
            title: 'Tema Aplikasi',
            description: 'Kode warna tema aplikasi (hex)',
            settingKey: 'app_theme_color',
          ),
          const SizedBox(height: 16),
          _buildSettingCard(
            title: 'Teks FAQ',
            description: 'Konten FAQ dalam format JSON',
            settingKey: 'faq_content',
            isMultiline: true,
          ),
          const SizedBox(height: 40),
          _buildSaveButton(),
        ],
      ),
    );
  }
  
  Widget _buildAnalyticsSettings(List<AppConfig> settings) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCategoryHeader('Pengaturan Analitik & Pelaporan'),
          const SizedBox(height: 16),
          // Tombol navigasi ke halaman laporan analitik
          Card(
            elevation: 3,
            child: InkWell(
              onTap: () => context.go('/admin/analytics'),
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withAlpha((255 * 0.1).round()),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.analytics,
                        color: Theme.of(context).primaryColor,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Laporan Analitik',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Lihat dan ekspor laporan transaksi, pesanan, dan perkembangan platform',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: Theme.of(context).primaryColor,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildSettingCard(
            title: 'Metrik Dashboard',
            description: 'Metrik yang ditampilkan di dashboard admin (pisahkan dengan koma)',
            settingKey: 'dashboard_metrics',
          ),
          const SizedBox(height: 16),
          _buildSettingCard(
            title: 'Periode Pelaporan',
            description: 'Frekuensi pembuatan laporan otomatis (dalam hari)',
            settingKey: 'reporting_period_days',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          _buildSettingCard(
            title: 'Ambang Batas Peringatan',
            description: 'Nilai ambang batas untuk peringatan otomatis (dalam persen)',
            settingKey: 'alert_threshold_percentage',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          _buildSettingCard(
            title: 'Kategori Laporan',
            description: 'Jenis laporan yang dapat diakses oleh berbagai tingkat admin (JSON)',
            settingKey: 'report_categories',
            isMultiline: true,
          ),
          const SizedBox(height: 16),
          _buildSettingCard(
            title: 'Format Ekspor Data',
            description: 'Format dan jenis data yang dapat diekspor (pisahkan dengan koma)',
            settingKey: 'export_data_formats',
          ),
          const SizedBox(height: 40),
          _buildSaveButton(),
        ],
      ),
    );
  }
  
  Widget _buildCategoryHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(0, 168, 200, 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color.fromRGBO(0, 168, 200, 0.3)),
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFF00A8C8),
        ),
      ),
    );
  }
  
  Widget _buildSettingCard({
    required String title,
    required String description,
    required String settingKey,
    bool isMultiline = false,
    TextInputType keyboardType = TextInputType.text,
    String? suffix,
  }) {
    // Pastikan controller ada untuk setting ini
    if (!_controllers.containsKey(settingKey)) {
      _controllers[settingKey] = TextEditingController();
    }
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _controllers[settingKey],
              keyboardType: keyboardType,
              maxLines: isMultiline ? 5 : 1,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                suffixText: suffix,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Nilai tidak boleh kosong';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _saveSettings,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00A8C8),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: const Text(
          'Simpan Pengaturan',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
  
  void _saveSettings() {
    if (_formKey.currentState?.validate() ?? false) {
      // Simpan semua pengaturan yang ada di tab aktif
      _controllers.forEach((key, controller) {
        context.read<AppSettingsBloc>().add(
          UpdateAppSettingEvent(
            key: key,
            value: controller.text,
          ),
        );
      });
    }
  }
}

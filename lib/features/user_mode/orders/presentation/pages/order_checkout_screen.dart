import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:klik_jasa/core/constants/app_colors.dart';
import 'package:klik_jasa/core/usecases/usecase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:klik_jasa/features/common/balance/domain/usecases/deduct_checkout_fee_usecase.dart';
import 'package:klik_jasa/features/common/profile/presentation/pages/top_up_screen.dart';
import 'package:klik_jasa/features/common/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:klik_jasa/features/common/notifications/domain/usecases/create_notification.dart';
import 'package:klik_jasa/features/common/profile/application/bloc/user_view_bloc.dart';
import 'package:klik_jasa/features/common/app_config/domain/usecases/get_user_fee_percentage.dart';
import 'package:klik_jasa/injection_container.dart' as di;
import 'package:klik_jasa/features/user_mode/home/domain/entities/service_with_location.dart';
import 'package:klik_jasa/features/common/utils/app_message_utils.dart';

class OrderCheckoutScreen extends StatefulWidget {
  final ServiceWithLocation service;

  const OrderCheckoutScreen({super.key, required this.service});

  @override
  State<OrderCheckoutScreen> createState() => _OrderCheckoutScreenState();
}

class _OrderCheckoutScreenState extends State<OrderCheckoutScreen> {
  // Fungsi untuk memformat angka dengan kaidah penulisan ribuan (10.000, 20.000, dst)
  String _formatCurrency(double amount) {
    // Menggunakan NumberFormat dari intl package
    // Jika intl package tidak tersedia, gunakan pendekatan manual
    String amountStr = amount.toStringAsFixed(0);
    String result = '';
    int count = 0;

    // Memformat angka dari belakang ke depan dengan titik setiap 3 digit
    for (int i = amountStr.length - 1; i >= 0; i--) {
      count++;
      result = amountStr[i] + result;
      if (count % 3 == 0 && i > 0) {
        result = '.$result';
      }
    }

    return result;
  }

  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  DateTime? _scheduledDate;
  TimeOfDay? _scheduledTime;
  bool _isLoading = false;

  // Use cases
  late final DeductCheckoutFeeUsecase _deductCheckoutFeeUsecase;
  late final GetCurrentUserUseCase _getCurrentUserUsecase;
  late final CreateNotification _createNotificationUsecase;
  late final GetUserFeePercentage _getUserFeePercentageUsecase;

  double get _servicePrice => widget.service.price;

  // Variabel untuk menyimpan persentase biaya aplikasi
  double _userFeePercentage = 5.0; // Default 5%
  bool _isLoadingFeePercentage =
      true; // Status loading persentase biaya aplikasi

  @override
  void initState() {
    super.initState();
    _deductCheckoutFeeUsecase = di.sl<DeductCheckoutFeeUsecase>();
    _getCurrentUserUsecase = di.sl<GetCurrentUserUseCase>();
    _createNotificationUsecase = di.sl<CreateNotification>();
    _getUserFeePercentageUsecase = di.sl<GetUserFeePercentage>();

    // Ambil persentase biaya aplikasi dari pengaturan
    _loadUserFeePercentage();
  }

  // Fungsi untuk mengambil persentase biaya aplikasi
  Future<void> _loadUserFeePercentage() async {
    final result = await _getUserFeePercentageUsecase(NoParams());
    result.fold(
      (failure) {
        // Jika gagal, gunakan nilai default 5%
        setState(() {
          _userFeePercentage = 5.0;
          _isLoadingFeePercentage = false;
        });
      },
      (percentage) {
        setState(() {
          _userFeePercentage = percentage;
          _isLoadingFeePercentage = false;
        });
      },
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Service Info Card
                    _buildServiceInfoCard(),
                    const SizedBox(height: 16),

                    // Schedule Section
                    _buildScheduleSection(),
                    const SizedBox(height: 16),

                    // Notes Section
                    _buildNotesSection(),
                    const SizedBox(height: 16),

                    // Price Breakdown
                    _buildPricingSection(),
                  ],
                ),
              ),
            ),

            // Bottom Action
            _buildBottomAction(),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceInfoCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detail Layanan',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.home_repair_service,
                    color: Colors.grey[600],
                    size: 30,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.service.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Oleh: ${widget.service.providerName}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Rp ${widget.service.price.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Jadwal',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 5),
                const Text(
                  '(Wajib)',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _selectDate,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Text(
                      _scheduledDate != null
                          ? '${_scheduledDate!.day}/${_scheduledDate!.month}/${_scheduledDate!.year}'
                          : 'Pilih tanggal',
                      style: TextStyle(
                        color: _scheduledDate != null
                            ? Colors.black
                            : Colors.grey[600],
                      ),
                    ),
                    const Spacer(),
                    if (_scheduledDate != null)
                      IconButton(
                        onPressed: () => setState(() => _scheduledDate = null),
                        icon: const Icon(Icons.clear),
                        iconSize: 20,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _selectTime,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.access_time, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Text(
                      _scheduledTime != null
                          ? '${_scheduledTime!.hour}:${_scheduledTime!.minute}'
                          : 'Pilih jam',
                      style: TextStyle(
                        color: _scheduledTime != null
                            ? Colors.black
                            : Colors.grey[600],
                      ),
                    ),
                    const Spacer(),
                    if (_scheduledTime != null)
                      IconButton(
                        onPressed: () => setState(() => _scheduledTime = null),
                        icon: const Icon(Icons.clear),
                        iconSize: 20,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Catatan (Opsional)',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Tambahkan catatan untuk penyedia layanan...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.primary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rincian Harga',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Harga Layanan'),
                Text('Rp ${_servicePrice.toStringAsFixed(0)}'),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  'Rp ${_servicePrice.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue[700],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Informasi Pembayaran',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _isLoadingFeePercentage
                      ? Row(
                          children: [
                            SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 8),
                            Text('Memuat informasi biaya aplikasi...'),
                          ],
                        )
                      : Text(
                          '• Pembayaran dilakukan secara tunai kepada penyedia layanan\n'
                          '• Pastikan layanan telah dikerjakan dengan baik sebelum melakukan pembayaran\n'
                          '• Biaya aplikasi ${_userFeePercentage.toStringAsFixed(1)}% akan dipotong otomatis dari saldo Anda\n'
                          '• Jika ada masalah, hubungi customer service KlikJasa',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.blue[700],
                            height: 1.4,
                          ),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomAction() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: const Color.fromRGBO(0, 0, 0, 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _processOrder,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  'Pesan Sekarang - Rp ${_servicePrice.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _scheduledDate) {
      setState(() {
        _scheduledDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null && picked != _scheduledTime) {
      setState(() {
        _scheduledTime = picked;
      });
    }
  }

  Future<void> _processOrder() async {
    if (!_formKey.currentState!.validate()) return;

    // Validasi jadwal tanggal dan jam
    if (_scheduledDate == null || _scheduledTime == null) {
      setState(() {
        _isLoading = false;
      });

      AppMessageUtils.showSnackbar(
        context: context,
        message: 'Jadwal tanggal dan jam wajib diisi',
        type: MessageType.error,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Dapatkan user saat ini
      final currentUserResult = await _getCurrentUserUsecase.call(NoParams());

      currentUserResult.fold(
        (failure) {
          if (mounted) {
            AppMessageUtils.showSnackbar(
              context: context,
              message: 'Error: ${failure.message}',
              type: MessageType.error,
            );
          }
          return;
        },
        (user) async {
          if (user == null) {
            if (mounted) {
              AppMessageUtils.showSnackbar(
                context: context,
                message: 'User tidak ditemukan',
                type: MessageType.error,
              );
            }
            return;
          }

          // Potong saldo berdasarkan persentase biaya aplikasi dari pengaturan admin
          final feeResult = await _deductCheckoutFeeUsecase.call(
            userId: user.id,
            servicePrice: _servicePrice,
            providerId: widget.service.providerId,
            feePercentage: _userFeePercentage,
          );

          feeResult.fold(
            (failure) {
              if (mounted) {
                // Cek apakah error terkait saldo tidak cukup
                if (failure.message.contains('Saldo tidak mencukupi') ||
                    failure.message.contains('Saldo tidak cukup')) {
                  // Tampilkan dialog notifikasi saldo tidak cukup dengan tombol aksi top up
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Row(
                          children: [
                            Icon(
                              Icons.account_balance_wallet,
                              color: Colors.red,
                            ),
                            SizedBox(width: 10),
                            Text('Saldo Tidak Cukup'),
                          ],
                        ),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Saldo Anda tidak mencukupi untuk melakukan transaksi ini. '
                              'Silakan lakukan top up saldo terlebih dahulu.',
                              style: TextStyle(fontSize: 16),
                            ),
                            SizedBox(height: 20),
                            Text(
                              'Informasi Saldo:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Minimal Saldo yang Diperlukan: Rp ${_formatCurrency((_servicePrice * _userFeePercentage / 100))}',
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: Text('Batal'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              // Navigasi ke halaman top up saldo menggunakan MaterialPageRoute
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const TopUpScreen(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                            ),
                            child: Text('Top Up Sekarang'),
                          ),
                        ],
                      );
                    },
                  );
                } else {
                  // Tampilkan snackbar untuk error lainnya
                  AppMessageUtils.showSnackbar(
                    context: context,
                    message: 'Gagal memproses biaya: ${failure.message}',
                    type: MessageType.error,
                  );
                }
              }
            },
            (success) async {
              // Format time before the async gap to avoid using BuildContext across async gaps.
              final formattedTime = _scheduledTime != null
                  ? ' pukul ${_scheduledTime!.format(context)}'
                  : '';

              // Debug: Periksa providerId sebelum membuat pesanan
              debugPrint(
                'Provider ID yang akan digunakan: ${widget.service.providerId}',
              );
              debugPrint('Service ID: ${widget.service.id}');
              debugPrint('Provider Name: ${widget.service.providerName}');

              // Verifikasi provider exists di database
              final providerCheck = await di
                  .sl<SupabaseClient>()
                  .from('profiles')
                  .select('id, full_name')
                  .eq('id', widget.service.providerId)
                  .maybeSingle();

              if (providerCheck == null) {
                debugPrint(
                  'ERROR: Provider dengan ID ${widget.service.providerId} tidak ditemukan di tabel profiles',
                );
                throw Exception(
                  'Provider tidak ditemukan. Silakan pilih layanan lain.',
                );
              }

              debugPrint('Provider ditemukan: ${providerCheck['full_name']}');

              // Implementasi API call untuk membuat pesanan - sesuaikan dengan struktur tabel orders
              final orderData = {
                'user_id': user.id,
                'provider_id': widget.service.providerId,
                'service_id': widget.service.id,
                'total_price': _servicePrice,
                'order_status':
                    'pending_confirmation', // Menggunakan enum order_status_enum yang benar
                'user_notes':
                    _notesController.text, // Menggunakan user_notes bukan notes
                'scheduled_date': _scheduledDate?.toIso8601String(),
                'quantity': 1, // Default quantity
                'fee_amount':
                    _servicePrice *
                    (_userFeePercentage /
                        100), // Menggunakan persentase dari pengaturan
                'fee_percentage':
                    _userFeePercentage, // Menyimpan persentase fee yang digunakan
                'fee_type':
                    'percentage', // Tipe fee yang digunakan (percentage atau fixed)
              };

              dynamic orderId;
              try {
                // Buat pesanan baru di tabel orders
                final response = await di
                    .sl<SupabaseClient>()
                    .from('orders')
                    .insert(orderData)
                    .select()
                    .single();
                orderId = response['id'];

                // Log untuk debugging
                debugPrint('Pesanan berhasil dibuat dengan ID: $orderId');
              } catch (e) {
                debugPrint('Error saat membuat pesanan: $e');
                throw Exception('Gagal membuat pesanan: $e');
              }

              // After an async gap, check if the widget is still mounted before using its context.
              if (!context.mounted) return;

              // Kirim notifikasi ke provider tentang pesanan baru
              final scheduledInfo = _scheduledDate != null
                  ? 'Dijadwalkan pada ${_scheduledDate!.day}/${_scheduledDate!.month}/${_scheduledDate!.year}$formattedTime'
                  : 'Segera';

              await _createNotificationUsecase(
                CreateNotificationParams(
                  recipientUserId: widget.service.providerId,
                  title: 'Pesanan Baru',
                  body:
                      'Anda menerima pesanan baru untuk layanan ${widget.service.title}. $scheduledInfo',
                  type:
                      'order_created', // FIX: Menggunakan tipe yang sesuai dengan backend
                  relatedEntityType: 'order',
                  relatedEntityId:
                      '$orderId', // FIX: Menggunakan ID pesanan yang baru dibuat
                  mode: 'provider', // Notifikasi untuk provider mode
                ),
              );

              if (mounted) {
                // Perbarui tampilan saldo di UI secara realtime
                context.read<UserViewBloc>().add(
                  UserViewUpdateBalance(userId: user.id),
                );

                // Hitung biaya layanan berdasarkan persentase dari pengaturan admin
                final serviceFee = _servicePrice * (_userFeePercentage / 100);

                // Tampilkan dialog sukses
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Pesanan Berhasil'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Pesanan Anda telah berhasil dibuat. Silakan hubungi penyedia layanan untuk koordinasi lebih lanjut.',
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Rincian Biaya:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Biaya Layanan (${_userFeePercentage.toStringAsFixed(0)}%):',
                                    ),
                                    Text(
                                      'Rp ${serviceFee.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Biaya ini telah dipotong dari saldo Anda',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop(); // Tutup dialog
                            context.pushReplacementNamed(
                              'orders-user',
                            ); // Ke daftar pesanan
                          },
                          child: const Text('Lihat Pesanan'),
                        ),
                      ],
                    );
                  },
                );
              }
            },
          );
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Terjadi kesalahan: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:klik_jasa/features/common/orders/domain/usecases/complete_order_usecase.dart';
import 'package:klik_jasa/injection_container.dart' as di;

class ProviderOrderDetailsScreen extends StatefulWidget {
  final int orderId;
  const ProviderOrderDetailsScreen({super.key, required this.orderId});

  @override
  State<ProviderOrderDetailsScreen> createState() =>
      _ProviderOrderDetailsScreenState();
}

class _ProviderOrderDetailsScreenState
    extends State<ProviderOrderDetailsScreen> {
  late Stream<Map<String, dynamic>> _streamOrderDetails;
  final _supabase = Supabase.instance.client;
  late CompleteOrderUseCase _completeOrderUseCase;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _streamOrderDetails = _watchOrderDetails();
    _completeOrderUseCase = di.sl<CompleteOrderUseCase>();
  }

  Stream<Map<String, dynamic>> _watchOrderDetails() {
    // Stream ini akan memantau perubahan pada pesanan yang sedang dilihat.
    return _supabase
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('id', widget.orderId)
        .asyncMap((listOfOrders) async {
      if (listOfOrders.isEmpty) {
        return {};
      }
      // Ambil data terbaru dari pesanan yang berubah.
      final orderData = listOfOrders.first;
      try {
        // Gunakan satu query JOIN untuk mengambil semua data terkait.
        // 'user:profiles(*)' akan mengambil semua data dari tabel 'profiles' yang terhubung
        // dan menempatkannya di dalam objek 'user'. Ini lebih efisien dan aman.
        final fullDetails = await _supabase
            .from('orders')
            .select('*, services(*), user:profiles!user_id(*)')
            .eq('id', orderData['id'])
            .single();

        // Pastikan 'user' dan 'services' tidak null untuk menghindari error di UI.
        fullDetails['user'] ??= {};
        fullDetails['services'] ??= {};

        return fullDetails;
      } catch (e) {
        debugPrint('Error fetching full order details: $e');
        // Jika terjadi error, kembalikan data dasar dengan pesan error.
        return {
          ...orderData, // Kembalikan data pesanan yang sudah ada
          'user': {'full_name': 'Gagal memuat data'},
          'services': {},
        };
      }
    });
  }

  Future<void> _completeOrder(Map<String, dynamic> order) async {
    // Tampilkan dialog konfirmasi
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Selesaikan Pesanan'),
        content: const Text(
          'Apakah Anda yakin ingin menandai pesanan ini sebagai selesai?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Ya, Selesaikan'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Ambil data yang diperlukan
      final int orderId = order['id'];
      final String? userId = order['user_id'];
      final String? providerId = order['provider_id'];
      final String? serviceTitle = order['services']?['title'];

      // Gunakan CompleteOrderUseCase untuk menyelesaikan pesanan dan mengirim notifikasi
      final result = await _completeOrderUseCase(
        CompleteOrderParams(
          orderId: orderId,
          userId: userId,
          providerId: providerId,
          serviceTitle: serviceTitle,
          notes: 'Pesanan telah diselesaikan oleh penyedia jasa',
        ),
      );

      result.fold(
        (failure) {
          if (!mounted) return;
          // Tampilkan pesan error
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal menyelesaikan pesanan: ${failure.message}'),
            ),
          );
        },
        (_) {
          if (!mounted) return;
          // Tampilkan pesan sukses
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pesanan berhasil diselesaikan')),
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Terjadi kesalahan: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Pesanan'), elevation: 1),
      body: StreamBuilder<Map<String, dynamic>>(
        stream: _streamOrderDetails,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('Detail pesanan tidak ditemukan.'));
          }

          final order = snapshot.data!;
          final service = order['services'] as Map<String, dynamic>;

          Map<String, dynamic> user = {};
          final rawUserData = order['user'];
          if (rawUserData is Map<String, dynamic>) {
            user = rawUserData;
          } else if (rawUserData is List && rawUserData.isNotEmpty) {
            user = rawUserData.first as Map<String, dynamic>;
          }

          // Tentukan apakah pesanan dapat diselesaikan (hanya jika statusnya 'in_progress')
          final bool canComplete = order['order_status'] == 'in_progress';

          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Informasi Layanan'),
                    _buildInfoCard(
                      icon: Icons.miscellaneous_services,
                      children: [
                        _buildDetailRow(
                          'Layanan:',
                          service['title'] ?? 'Tidak tersedia',
                        ),
                        _buildDetailRow(
                          'Deskripsi:',
                          service['description'] ?? 'Tidak tersedia',
                        ),
                        _buildDetailRow(
                          'Harga Satuan:',
                          NumberFormat.currency(
                            locale: 'id_ID',
                            symbol: 'Rp ',
                            decimalDigits: 0,
                          ).format(service['price'] ?? 0).replaceAll(',', '.'),
                        ),
                        if (service['price_unit'] != null &&
                            service['price_unit'].toString().trim().isNotEmpty)
                          _buildDetailRow(
                            'Satuan Harga:',
                            _formatPriceUnit(service['price_unit']),
                          ),
                        if (service['location_text'] != null &&
                            service['location_text']
                                .toString()
                                .trim()
                                .isNotEmpty)
                          _buildDetailRow(
                            'Lokasi Layanan:',
                            service['location_text'],
                          ),
                        if (order['quantity'] != null)
                          _buildDetailRow('Jumlah:', '${order['quantity']}'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildSectionTitle('Informasi Pemesan'),
                    _buildInfoCard(
                      icon: Icons.person,
                      children: [
                        _buildDetailRow(
                          'Pemesan:',
                          user['full_name'] ?? 'Pengguna',
                        ),
                        _buildDetailRow('Alamat:', _buildFullAddress(user)),
                        _buildDetailRow(
                          'Telepon:',
                          _formatPhoneNumber(user['phone_number']),
                        ),
                        if (user['email'] != null &&
                            user['email'].toString().trim().isNotEmpty)
                          _buildDetailRow('Email:', user['email']),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildSectionTitle('Detail Pesanan'),
                    _buildInfoCard(
                      icon: Icons.receipt_long,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const SizedBox(
                                width: 80,
                                child: Text('Status:',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w500)),
                              ),
                              const Text(' :  '),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 2, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(
                                        order['order_status'] ?? 'unknown'),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    _formatOrderStatus(
                                        order['order_status'] ?? 'unknown'),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        _buildDetailRow(
                          'Tanggal Pesan:',
                          DateFormat(
                            'dd MMM yyyy, HH:mm',
                          ).format(DateTime.parse(order['created_at'])),
                        ),
                        if (order['scheduled_date'] != null)
                          _buildDetailRow(
                            'Tanggal Terjadwal:',
                            DateFormat(
                              'dd MMM yyyy, HH:mm',
                            ).format(DateTime.parse(order['scheduled_date'])),
                          ),
                        _buildDetailRow(
                          'Catatan Pengguna:',
                          order['user_notes'] ?? 'Tidak ada catatan',
                        ),
                        if (order['provider_notes'] != null &&
                            order['provider_notes']
                                .toString()
                                .trim()
                                .isNotEmpty)
                          _buildDetailRow(
                            'Catatan Penyedia:',
                            order['provider_notes'],
                          ),
                        if (order['cancellation_reason'] != null &&
                            order['cancellation_reason']
                                .toString()
                                .trim()
                                .isNotEmpty)
                          _buildDetailRow(
                            'Alasan Pembatalan:',
                            order['cancellation_reason'],
                          ),
                        if (order['completion_date'] != null)
                          _buildDetailRow(
                            'Tanggal Selesai:',
                            DateFormat(
                              'dd MMM yyyy, HH:mm',
                            ).format(DateTime.parse(order['completion_date'])),
                          ),
                        const Divider(height: 20),
                        _buildPriceRow(
                          'Total Harga:',
                          order['total_price'] ?? 0,
                        ),
                        _buildPriceRow(
                          'Biaya Aplikasi:',
                          order['fee_amount'] ?? 0,
                        ),
                        // Menampilkan persentase biaya aplikasi jika tersedia
                        if (order['fee_percentage'] != null)
                          _buildDetailRow(
                            'Persentase Biaya:',
                            '${order['fee_percentage']}%',
                          )
                        // Alternatif jika fee_percentage tidak ada tapi fee_amount ada
                        else if (order['fee_amount'] != null && order['total_price'] != null && order['total_price'] > 0)
                          _buildDetailRow(
                            'Persentase Biaya:',
                            '${((order['fee_amount'] / order['total_price']) * 100).toStringAsFixed(1)}%',
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Tombol untuk menyelesaikan pesanan
              if (canComplete)
                Positioned(
                  bottom: 20,
                  left: 16,
                  right: 16,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: _isLoading ? null : () => _completeOrder(order),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Selesaikan Pesanan'),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(title, style: Theme.of(context).textTheme.titleLarge),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _buildFullAddress(Map<String, dynamic> user) {
    // Membangun alamat lengkap dari beberapa field.
    final address = user['address']?.toString().trim() ?? '';
    if (address.isNotEmpty) {
      return address;
    }

    // Jika 'address' kosong, coba bangun dari bagian-bagiannya.
    final List<String> addressParts = [
      user['desa_kelurahan']?.toString().trim(),
      user['kecamatan']?.toString().trim(),
      user['kabupaten_kota']?.toString().trim(),
      user['provinsi']?.toString().trim(),
      user['postal_code']?.toString().trim(),
    ].where((part) => part != null && part.isNotEmpty).map((part) => part!).toList();

    if (addressParts.isNotEmpty) {
      return addressParts.join(', ');
    }

    return 'Alamat tidak tersedia';
  }

  String _formatPhoneNumber(dynamic phoneNumber) {
    // Tangani kasus di mana phoneNumber adalah null atau string kosong
    if (phoneNumber == null || phoneNumber.toString().trim().isEmpty) {
      return 'Nomor telepon tidak tersedia';
    }

    // Jika phoneNumber adalah 'Tidak tersedia', kembalikan itu
    if (phoneNumber.toString().trim() == 'Tidak tersedia') {
      return 'Nomor telepon tidak tersedia';
    }

    String phone = phoneNumber.toString().trim();

    // Log untuk debugging
    debugPrint('Memformat nomor telepon: $phone');

    // Jika nomor telepon tidak dimulai dengan +62 atau 0, tambahkan 0 di depan
    if (!phone.startsWith('+62') && !phone.startsWith('0')) {
      phone = '0$phone';
    }

    // Jika nomor telepon dimulai dengan +62, ganti dengan 0
    if (phone.startsWith('+62')) {
      phone = '0${phone.substring(3)}';
    }

    // Format nomor telepon Indonesia (contoh: 0812-3456-7890)
    if (phone.length >= 10) {
      try {
        // Hapus semua karakter non-digit
        final digits = phone.replaceAll(RegExp(r'\D'), '');

        if (digits.length >= 10) {
          // Format nomor telepon dengan pemisah
          final firstPart = digits.substring(0, 4);
          final secondPart = digits.substring(4, math.min(8, digits.length));
          final thirdPart = digits.length > 8 ? digits.substring(8) : '';

          if (thirdPart.isNotEmpty) {
            return '$firstPart-$secondPart-$thirdPart';
          } else if (secondPart.isNotEmpty) {
            return '$firstPart-$secondPart';
          } else {
            return firstPart;
          }
        }
      } catch (e) {
        // Jika terjadi kesalahan saat memformat, kembalikan nomor asli
        return phone;
      }
    }

    // Jika tidak memenuhi syarat untuk diformat, kembalikan nomor asli
    return phone;
  }

  Widget _buildPriceRow(String label, num value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(
            NumberFormat.currency(
              locale: 'id_ID',
              symbol: 'Rp ',
              decimalDigits: 0,
            ).format(value).replaceAll(',', '.'),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }

  String _formatOrderStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending_confirmation':
        return 'Menunggu Konfirmasi';
      case 'accepted_by_provider':
        return 'Diterima';
      case 'rejected_by_provider':
        return 'Ditolak';
      case 'in_progress':
        return 'Sedang Dikerjakan';
      case 'completed_by_provider':
        return 'Diselesaikan';
      case 'cancelled_by_user':
        return 'Dibatalkan Pengguna';
      case 'cancelled_by_provider':
        return 'Dibatalkan Penyedia';
      case 'disputed':
        return 'Dalam Sengketa';
      // Fallback for old statuses if any
      case 'confirmed':
        return 'Dikonfirmasi';
      case 'completed':
        return 'Selesai';
      case 'rejected':
        return 'Ditolak';
      default:
        return 'Status Tidak Diketahui';
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending_confirmation':
        return Colors.orange;
      case 'accepted_by_provider':
        return Colors.blue;
      case 'in_progress':
        return Colors.indigo;
      case 'completed_by_provider':
        return Colors.green;
      case 'rejected_by_provider':
      case 'cancelled_by_user':
      case 'cancelled_by_provider':
        return Colors.red;
      case 'disputed':
        return Colors.purple;
      // Fallback for old statuses if any
      case 'confirmed':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatPriceUnit(String unit) {
    // Mengubah format satuan harga menjadi lebih mudah dibaca
    switch (unit.toLowerCase()) {
      case 'hour':
        return 'Per Jam';
      case 'day':
        return 'Per Hari';
      case 'week':
        return 'Per Minggu';
      case 'month':
        return 'Per Bulan';
      case 'project':
        return 'Per Proyek';
      case 'session':
        return 'Per Sesi';
      case 'visit':
        return 'Per Kunjungan';
      case 'unit':
        return 'Per Unit';
      case 'person':
        return 'Per Orang';
      case 'sqm':
        return 'Per Meter Persegi';
      case 'kg':
        return 'Per Kilogram';
      default:
        // Jika tidak ada dalam daftar, tampilkan dengan format yang lebih baik
        // Misalnya: 'item' menjadi 'Per Item'
        return 'Per ${unit.substring(0, 1).toUpperCase()}${unit.substring(1)}';
    }
  }
}

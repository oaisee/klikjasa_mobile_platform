import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:klik_jasa/features/common/utils/app_message_utils.dart';

// Model untuk data layanan
class Layanan {
  final int id;
  final String judul;
  final String deskripsi;
  final double harga;
  final String? satuanHarga;
  bool isActive; // Dapat diubah
  final DateTime createdAt;
  final String namaPenyedia;
  final String namaKategori;

  Layanan({
    required this.id,
    required this.judul,
    required this.deskripsi,
    required this.harga,
    this.satuanHarga,
    required this.isActive,
    required this.createdAt,
    required this.namaPenyedia,
    required this.namaKategori,
  });

  factory Layanan.fromJson(Map<String, dynamic> json) {
    final providerData = json['profiles'] != null ? Map<String, dynamic>.from(json['profiles']) : null;
final categoryData = json['service_categories'] != null ? Map<String, dynamic>.from(json['service_categories']) : null;

    return Layanan(
      id: json['id'] is int ? json['id'] : 0,
      judul: json['title'] is String ? json['title'] : '',
      deskripsi: json['description'] is String ? json['description'] : '',
      harga: json['price'] is num ? json['price'].toDouble() : 0.0,
      satuanHarga: json['price_unit'] is String ? json['price_unit'] : null,
      isActive: json['is_active'] is bool ? json['is_active'] : false,
      createdAt: json['created_at'] is String ? DateTime.parse(json['created_at']) : DateTime.now(),
      namaPenyedia: providerData?['full_name'] is String ? providerData!['full_name'] : 'Penyedia Tidak Ada',
      namaKategori: categoryData?['name'] is String ? categoryData!['name'] : 'Kategori Tidak Ada',
    );
  }
}

class ServiceManagementScreen extends StatefulWidget {
  const ServiceManagementScreen({super.key});

  @override
  State<ServiceManagementScreen> createState() => _ServiceManagementScreenState();
}

class _ServiceManagementScreenState extends State<ServiceManagementScreen> {
  List<Layanan>? _layananList;
  bool _isLoading = true;
  String? _errorMessage;
  final SupabaseClient _supabaseClient = Supabase.instance.client;
  final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ');

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final data = await _supabaseClient
          .from('services')
          .select('''
            id,
            title,
            description,
            price,
            price_unit,
            is_active,
            created_at,
            profiles ( full_name ), 
            service_categories ( name )
          ''')
          .order('created_at', ascending: false);

      _layananList = data.map((item) => Layanan.fromJson(item)).toList();
    } catch (e) {
      _errorMessage = 'Gagal mengambil data layanan: ${e.toString()}';
      if (mounted) {
        AppMessageUtils.showSnackbar(
          context: context,
          message: _errorMessage!,
          type: MessageType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleServiceStatus(Layanan layanan, bool newStatus) async {
    try {
      await _supabaseClient
          .from('services')
          .update({'is_active': newStatus})
          .eq('id', layanan.id);

      if (mounted) {
        setState(() {
          final index = _layananList?.indexWhere((s) => s.id == layanan.id);
          if (index != null && index != -1) {
            _layananList?[index].isActive = newStatus;
          }
        });
        AppMessageUtils.showSnackbar(
          context: context,
          message: 'Status layanan berhasil diperbarui.',
          type: MessageType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        AppMessageUtils.showSnackbar(
          context: context,
          message: 'Gagal memperbarui status layanan: ${e.toString()}',
          type: MessageType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadServices();
        },
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null && _layananList == null) {
      // Tampilkan error hanya jika tidak ada data sama sekali
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _errorMessage!,
            style: const TextStyle(color: Colors.red, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_layananList == null || _layananList!.isEmpty) {
      return const Center(child: Text('Tidak ada layanan yang ditemukan.'));
    }

    return ListView.builder(
      itemCount: _layananList!.length,
      itemBuilder: (context, index) {
        final layanan = _layananList![index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: ListTile(
            title: Text(layanan.judul, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Penyedia: ${layanan.namaPenyedia}'),
                Text('Kategori: ${layanan.namaKategori}'),
                Text('Harga: ${currencyFormatter.format(layanan.harga)}${layanan.satuanHarga != null ? " /${layanan.satuanHarga}" : ""}'),
                Text('Status: ${layanan.isActive ? "Aktif" : "Tidak Aktif"}', 
                  style: TextStyle(color: layanan.isActive ? Colors.green : Colors.orange)
                ),
              ],
            ),
            trailing: Switch(
              value: layanan.isActive,
              onChanged: (bool newValue) {
                _toggleServiceStatus(layanan, newValue);
              },
              activeColor: Colors.green,
            ),
            isThreeLine: true, // Agar subtitle bisa lebih tinggi
          ),
        );
      },
    );
  }
}

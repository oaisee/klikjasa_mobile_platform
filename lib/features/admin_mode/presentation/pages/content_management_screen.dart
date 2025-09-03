import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:klik_jasa/core/constants/app_colors.dart'; // Asumsi path ini benar
import 'add_edit_banner_screen.dart';
import '../../domain/entities/promotional_banner.dart';


class ContentManagementScreen extends StatefulWidget {
  const ContentManagementScreen({super.key});

  @override
  State<ContentManagementScreen> createState() => _ContentManagementScreenState();
}

class _ContentManagementScreenState extends State<ContentManagementScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<PromotionalBanner> _banners = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchBanners();
  }

  Future<void> _fetchBanners() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await _supabase
          .from('promotional_banners')
          .select()
          .order('sort_order', ascending: true);

      final List<dynamic> data = List<dynamic>.from(response); // Konversi response ke List<dynamic>
      _banners = data.map((item) => PromotionalBanner.fromJson(Map<String, dynamic>.from(item))).toList();
    } catch (e) {
      _error = 'Gagal mengambil data banner: ${e.toString()}';
      _banners = []; // Kosongkan banner jika ada error
      debugPrint(_error.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _navigateToAddBannerScreen() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const AddEditBannerScreen()),
    );
    if (result == true && mounted) {
      _fetchBanners(); // Refresh daftar jika ada perubahan
    }
  }

  Future<void> _navigateToEditBannerScreen(PromotionalBanner banner) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => AddEditBannerScreen(banner: banner)),
    );
    if (result == true && mounted) {
      _fetchBanners(); // Refresh daftar jika ada perubahan
    }
  }

  // TODO: Implementasi _deleteBanner
  Future<void> _deleteBanner(int bannerId) async {
    // Tampilkan dialog konfirmasi
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: const Text('Apakah Anda yakin ingin menghapus banner ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Hapus', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _supabase.from('promotional_banners').delete().match({'id': bannerId });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Banner berhasil dihapus'), backgroundColor: Colors.green),
          );
          _fetchBanners(); // Refresh daftar banner
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menghapus banner: ${e.toString()}'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : _banners.isEmpty
                  ? const Center(child: Text('Belum ada banner promosi.'))
                  : RefreshIndicator(
                      onRefresh: _fetchBanners,
                      child: ListView.builder(
                        itemCount: _banners.length,
                        itemBuilder: (context, index) {
                          final banner = _banners[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            elevation: 3,
                            child: ListTile(
                              leading: banner.imageUrl.startsWith('http')
                                  ? Image.network(banner.imageUrl, width: 80, height: 50, fit: BoxFit.cover, errorBuilder: (c, o, s) => const Icon(Icons.broken_image, size: 40))
                                  : const Icon(Icons.image_not_supported, size: 40), // Placeholder jika URL tidak valid
                              title: Text(banner.title ?? 'Tanpa Judul', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Aktif: ${banner.isActive ? 'Ya' : 'Tidak'}'),
                                  Text('Urutan: ${banner.sortOrder}'),
                                  if (banner.targetUrl != null && banner.targetUrl!.isNotEmpty)
                                    Text('Link: ${banner.targetUrl}', style: const TextStyle(color: Colors.blue, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: AppColors.accent),
                                    onPressed: () => _navigateToEditBannerScreen(banner),
                                    tooltip: 'Edit Banner',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                                    onPressed: () => _deleteBanner(banner.id),
                                    tooltip: 'Hapus Banner',
                                  ),
                                ],
                              ),
                              isThreeLine: true,
                            ),
                          );
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAddBannerScreen,
        icon: const Icon(Icons.add_photo_alternate_outlined),
        label: const Text('Tambah Banner'),
        backgroundColor: AppColors.accent,
      ),
    );
  }
}

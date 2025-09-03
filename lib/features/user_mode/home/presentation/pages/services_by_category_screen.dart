import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:klik_jasa/core/constants/app_colors.dart';
import 'package:klik_jasa/features/common/services/domain/entities/service_category.dart';
import 'package:klik_jasa/features/user_mode/home/presentation/widgets/layanan_list_item.dart';

/// Halaman untuk menampilkan daftar layanan berdasarkan kategori
class ServicesByCategoryScreen extends StatefulWidget {
  final ServiceCategory category;

  const ServicesByCategoryScreen({
    super.key,
    required this.category,
  });

  @override
  State<ServicesByCategoryScreen> createState() => _ServicesByCategoryScreenState();
}

class _ServicesByCategoryScreenState extends State<ServicesByCategoryScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _services = [];

  @override
  void initState() {
    super.initState();
    debugPrint('Initializing ServicesByCategoryScreen with category: ${widget.category}');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchServicesByCategory();
    });
  }

  Future<void> _fetchServicesByCategory() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      debugPrint('Fetching services for category ID: ${widget.category.id}');
      
      // ID sudah dijamin tidak null karena tipe data String non-nullable

      // Mengambil layanan berdasarkan kategori dari Supabase
      final response = await _supabase
          .from('services')
          .select()
          .eq('category_id', widget.category.id)
          .eq('is_active', true)
          .order('created_at', ascending: false);

      debugPrint('Received ${response.length} services for category ${widget.category.name}');

      if (!mounted) return;

      setState(() {
        _services = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      debugPrint('Error fetching services: $e');
      debugPrint('Stack trace: $stackTrace');
      
      if (!mounted) return;
      setState(() {
        _error = 'Gagal memuat layanan: ${e.toString()}. Silakan coba lagi.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        backgroundColor: AppColors.primary,
        title: Text(
          'Layanan ${widget.category.name}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchServicesByCategory,
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    if (_services.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.search_off,
                color: Colors.grey,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Belum ada layanan untuk kategori ${widget.category.name}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _services.length,
      itemBuilder: (context, index) {
        final service = _services[index];
        return LayananListItem(
          judul: service['title'],
          penyedia: 'Penyedia Jasa',  // Bisa diganti dengan nama penyedia jika tersedia
          harga: 'Rp${service['price'].toString()}',
          urlGambar: service['images_urls'] != null && 
                   (service['images_urls'] as List).isNotEmpty 
                   ? service['images_urls'][0] 
                   : null,
          rating: service['average_rating']?.toDouble() ?? 0.0,
        );
      },
    );
  }
}

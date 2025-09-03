import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klik_jasa/core/utils/logger.dart';
import 'package:klik_jasa/features/common/services/domain/entities/service_category.dart';
import 'package:klik_jasa/features/common/services/domain/utils/category_icon_mapper.dart';
import 'package:klik_jasa/features/user_mode/home/presentation/cubit/category_cubit.dart';
import 'package:klik_jasa/features/user_mode/home/presentation/cubit/category_state.dart';
import 'package:klik_jasa/features/user_mode/home/presentation/pages/services_by_category_screen.dart';

/// Widget untuk menampilkan grid kategori layanan di halaman Beranda
class CategoryGridWidget extends StatefulWidget {
  const CategoryGridWidget({super.key});

  @override
  State<CategoryGridWidget> createState() => _CategoryGridWidgetState();
}

class _CategoryGridWidgetState extends State<CategoryGridWidget> {
  @override
  void initState() {
    super.initState();
    // Debug: Cetak saat widget diinisialisasi
    logger.i('🔄 CategoryGridWidget - initState: Memuat kategori layanan...');
    
    // Muat kategori layanan saat widget diinisialisasi
    context.read<CategoryCubit>().getActiveCategories();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CategoryCubit, CategoryState>(
      builder: (context, state) {
        if (state is CategoryLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          );
        } else if (state is CategoryLoaded) {
          return _buildCategoryGrid(state.categories);
        } else if (state is CategoryError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Error: ${state.message}',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          );
        } else {
          return const SizedBox.shrink();
        }
      },
    );
  }

  Widget _buildCategoryGrid(List<ServiceCategory> categories) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kategori Layanan',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
          ),
          const SizedBox(height: 2),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 0.9,
              crossAxisSpacing: 12.0,
              mainAxisSpacing: 12.0,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return _buildCategoryItem(context, category);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(BuildContext context, ServiceCategory category) {
    final color = _getCategoryColor(category.name);
    
    // Debug log untuk melihat nama kategori dan iconName yang diproses
    logger.d('🔍 CategoryGridWidget - _buildCategoryItem:');
    logger.d('  • Nama kategori: "${category.name}"');
    logger.d('  • iconName dari database: ${category.iconName ?? "<tidak ada>"}');
    logger.d('  • ID kategori: ${category.id}');
    
    // Mendapatkan ikon yang unik berdasarkan kategori
    IconData iconData;
    
    // Pemetaan kategori ke ikon yang lebih spesifik dan unik
    final Map<String, IconData> customCategoryIcons = {
      'Tukang Bangunan': Icons.construction_rounded,
      'Transportasi': Icons.directions_bus_rounded,
      'Teknologi & Digital': Icons.computer_rounded,
      'Taman & Pertamanan': Icons.yard_rounded,
      'Pindahan & Angkut': Icons.local_shipping_rounded,
      'Perbaikan & Instalasi': Icons.build_rounded,
      'Pendidikan & Pelatihan': Icons.school_rounded,
      'Otomotif (motor)': Icons.two_wheeler_rounded,
      'Otomotif (Mobil)': Icons.directions_car_rounded,
      'Kecantikan & Kesehatan': Icons.spa_rounded,
      'Kebersihan': Icons.cleaning_services_rounded,
      'Home Interior': Icons.chair_rounded,
      'Home Exterior': Icons.cottage_rounded,
      'Hewan Peliharaan': Icons.pets_rounded,
      'Event & Acara': Icons.celebration_rounded,
      'Desain & Kreatif': Icons.design_services_rounded,
      'Administrasi & Keuangan': Icons.account_balance_rounded,
      'Kuliner': Icons.restaurant_rounded,
      'Laundry': Icons.local_laundry_service_rounded,
      'Elektronik': Icons.electrical_services_rounded,
      'Komputer': Icons.laptop_mac_rounded,
      'Fotografi': Icons.camera_alt_rounded,
      'Video': Icons.videocam_rounded,
      'Kesehatan': Icons.medical_services_rounded,
      'Olahraga': Icons.sports_rounded,
      'Hiburan': Icons.music_note_rounded,
      'Hukum': Icons.gavel_rounded,
    };
    
    // Cek apakah kategori ada di pemetaan kustom
    if (customCategoryIcons.containsKey(category.name)) {
      iconData = customCategoryIcons[category.name]!;
      logger.d('  ✅ Menggunakan ikon kustom untuk kategori: ${category.name} -> $iconData');
    }
    // Jika tidak ada di pemetaan kustom, coba dengan iconName dari database
    else if (category.iconName != null && category.iconName!.isNotEmpty) {
      iconData = CategoryIconMapper.getIconData(category.name, iconName: category.iconName);
      logger.d('  ✅ Menggunakan iconName dari database: ${category.iconName} -> $iconData');
    } 
    // Jika tidak ada iconName, gunakan nama kategori
    else {
      iconData = CategoryIconMapper.getIconData(category.name);
      logger.d('  ⚠️ iconName kosong, menggunakan nama kategori: ${category.name} -> $iconData');
    }
    
    // Dapatkan CategoryIcon untuk mendapatkan label yang lebih deskriptif
    final categoryIcon = CategoryIconMapper.getCategoryIconByName(category.iconName ?? category.name);
    final iconLabel = categoryIcon?.label ?? category.name;
    
    // Debug log untuk ikon yang didapat
    logger.d('  📊 Hasil akhir untuk kategori "${category.name}": icon=$iconData, label=$iconLabel, color=$color');
    
    // Tambahkan log untuk membantu troubleshooting
    if (iconData.codePoint == Icons.star.codePoint) {
      logger.w('  ⚠️ PERHATIAN: Menggunakan icon bintang default untuk kategori "${category.name}"');
      logger.w('  ⚠️ iconName: ${category.iconName}, codePoint: ${iconData.codePoint}');
    } else {
      logger.d('  ✅ Berhasil mendapatkan icon unik untuk kategori "${category.name}"');
    }
    
    return InkWell(
      onTap: () => _navigateToServicesByCategory(context, category),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color.fromRGBO(158, 158, 158, 0.2),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Menggunakan CircleAvatar dengan background color seperti di admin_mode
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.2),
              radius: 22,
              child: Icon(
                iconData,
                size: 26,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              category.name,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12,
                color: Colors.black,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // Navigasi ke halaman layanan berdasarkan kategori
  void _navigateToServicesByCategory(BuildContext context, ServiceCategory category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ServicesByCategoryScreen(category: category),
      ),
    );
  }

  // Mendapatkan warna cerah dan modern untuk setiap kategori
  Color _getCategoryColor(String categoryName) {
    final String nameLower = categoryName.toLowerCase();
    
    // Warna cerah dan modern yang lebih menarik
    if (nameLower.contains('kebersihan') || nameLower.contains('bersih')) {
      return const Color(0xFF00B4D8); // Biru cerah
    } else if (nameLower.contains('perbaikan') || nameLower.contains('repair')) {
      return const Color(0xFFF77F00); // Oranye cerah
    } else if (nameLower.contains('transportasi') || nameLower.contains('transport')) {
      return const Color(0xFFEF476F); // Merah muda cerah
    } else if (nameLower.contains('kesehatan') || nameLower.contains('health')) {
      return const Color(0xFFF72585); // Merah muda tua
    } else if (nameLower.contains('kecantikan') || nameLower.contains('beauty')) {
      return const Color(0xFFB5179E); // Ungu muda
    } else if (nameLower.contains('pendidikan') || 
               nameLower.contains('education') || 
               nameLower.contains('pelatihan')) {
      return const Color(0xFFF9C74F); // Kuning cerah
    } else if (nameLower.contains('teknologi') || nameLower.contains('tech')) {
      return const Color(0xFF4CC9F0); // Biru muda cerah
    } else if (nameLower.contains('kuliner') || nameLower.contains('food')) {
      return const Color(0xFFF94144); // Merah cerah
    } else if (nameLower.contains('olahraga') || nameLower.contains('sport')) {
      return const Color(0xFF43AA8B); // Hijau toska
    } else if (nameLower.contains('hiburan') || nameLower.contains('entertainment')) {
      return const Color(0xFF7209B7); // Ungu cerah
    } else if (nameLower.contains('acara') || nameLower.contains('event')) {
      return const Color(0xFFF8961E); // Oranye kekuningan
    } else {
      // Generate warna deterministik berdasarkan nama kategori
      final hash = categoryName.codeUnits.fold(0, (a, b) => a + b);
      final colors = [
        const Color(0xFF00B4D8), // Biru cerah
        const Color(0xFFF77F00), // Oranye cerah
        const Color(0xFFEF476F), // Merah muda cerah
        const Color(0xFFF72585), // Merah muda tua
        const Color(0xFFB5179E), // Ungu muda
        const Color(0xFF4CC9F0), // Biru muda cerah
        const Color(0xFF43AA8B), // Hijau toska
        const Color(0xFF7209B7), // Ungu cerah
      ];
      return colors[hash % colors.length];
    }
  }
}

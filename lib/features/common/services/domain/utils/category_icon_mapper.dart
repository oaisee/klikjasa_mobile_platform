import 'package:flutter/material.dart';
import 'package:klik_jasa/core/utils/logger.dart';

/// Model untuk menyimpan data icon kategori
class CategoryIcon {
  final String name;
  final IconData icon;
  final String label;
  final String? description;
  final String category;

  const CategoryIcon({
    required this.name,
    required this.icon,
    required this.label,
    this.description,
    required this.category,
  });
}

/// Utility class untuk memetakan nama kategori ke ikon yang sesuai
class CategoryIconMapper {
  // Private constructor untuk mencegah instantiasi
  CategoryIconMapper._();

  /// Daftar semua icon kategori yang tersedia
  static final List<CategoryIcon> allIcons = [
    // Kebersihan
    const CategoryIcon(
      name: 'cleaning_services',
      icon: Icons.cleaning_services_rounded,
      label: 'Layanan Kebersihan',
      description: 'Icon untuk layanan pembersihan rumah, kantor, dll',
      category: 'Kebersihan',
    ),
    const CategoryIcon(
      name: 'wash',
      icon: Icons.wash_rounded,
      label: 'Cuci',
      description: 'Icon untuk layanan pencucian',
      category: 'Kebersihan',
    ),
    
    // Perbaikan & Perawatan
    const CategoryIcon(
      name: 'handyman',
      icon: Icons.handyman_rounded,
      label: 'Tukang',
      description: 'Icon untuk layanan perbaikan umum',
      category: 'Perbaikan',
    ),
    const CategoryIcon(
      name: 'build',
      icon: Icons.build_rounded,
      label: 'Perbaikan',
      description: 'Icon untuk layanan perbaikan dan konstruksi',
      category: 'Perbaikan',
    ),
    const CategoryIcon(
      name: 'home_repair_service',
      icon: Icons.home_repair_service_rounded,
      label: 'Perbaikan Rumah',
      description: 'Icon untuk layanan perbaikan rumah',
      category: 'Perbaikan',
    ),
    
    // Elektronik & Listrik
    const CategoryIcon(
      name: 'electrical_services',
      icon: Icons.electrical_services_rounded,
      label: 'Layanan Listrik',
      description: 'Icon untuk layanan kelistrikan',
      category: 'Elektronik',
    ),
    const CategoryIcon(
      name: 'devices',
      icon: Icons.devices_rounded,
      label: 'Perangkat',
      description: 'Icon untuk layanan perangkat elektronik',
      category: 'Elektronik',
    ),
    
    // Komputer & IT
    const CategoryIcon(
      name: 'computer',
      icon: Icons.computer_rounded,
      label: 'Komputer',
      description: 'Icon untuk layanan komputer',
      category: 'Teknologi',
    ),
    const CategoryIcon(
      name: 'laptop',
      icon: Icons.laptop_rounded,
      label: 'Laptop',
      description: 'Icon untuk layanan laptop',
      category: 'Teknologi',
    ),
    const CategoryIcon(
      name: 'phone_android',
      icon: Icons.phone_android_rounded,
      label: 'Smartphone',
      description: 'Icon untuk layanan smartphone',
      category: 'Teknologi',
    ),
    const CategoryIcon(
      name: 'code',
      icon: Icons.code_rounded,
      label: 'Pemrograman',
      description: 'Icon untuk layanan pemrograman',
      category: 'Teknologi',
    ),
    
    // Transportasi
    const CategoryIcon(
      name: 'directions_car',
      icon: Icons.directions_car_rounded,
      label: 'Mobil',
      description: 'Icon untuk layanan mobil',
      category: 'Transportasi',
    ),
    const CategoryIcon(
      name: 'two_wheeler',
      icon: Icons.two_wheeler_rounded,
      label: 'Motor',
      description: 'Icon untuk layanan motor',
      category: 'Transportasi',
    ),
    const CategoryIcon(
      name: 'directions_bus',
      icon: Icons.directions_bus_rounded,
      label: 'Bus',
      description: 'Icon untuk layanan transportasi umum',
      category: 'Transportasi',
    ),
    
    // Rumah & Properti
    const CategoryIcon(
      name: 'house',
      icon: Icons.house_rounded,
      label: 'Rumah',
      description: 'Icon untuk layanan rumah',
      category: 'Properti',
    ),
    const CategoryIcon(
      name: 'apartment',
      icon: Icons.apartment_rounded,
      label: 'Apartemen',
      description: 'Icon untuk layanan apartemen',
      category: 'Properti',
    ),
    const CategoryIcon(
      name: 'yard',
      icon: Icons.yard_rounded,
      label: 'Taman',
      description: 'Icon untuk layanan taman',
      category: 'Properti',
    ),
    const CategoryIcon(
      name: 'grass',
      icon: Icons.grass_rounded,
      label: 'Rumput',
      description: 'Icon untuk layanan perawatan rumput',
      category: 'Properti',
    ),
    
    // Utilitas Rumah
    const CategoryIcon(
      name: 'plumbing',
      icon: Icons.plumbing_rounded,
      label: 'Pipa',
      description: 'Icon untuk layanan pipa dan ledeng',
      category: 'Utilitas',
    ),
    const CategoryIcon(
      name: 'format_paint',
      icon: Icons.format_paint_rounded,
      label: 'Cat',
      description: 'Icon untuk layanan pengecatan',
      category: 'Utilitas',
    ),
    const CategoryIcon(
      name: 'ac_unit',
      icon: Icons.ac_unit_rounded,
      label: 'AC',
      description: 'Icon untuk layanan AC',
      category: 'Utilitas',
    ),
    
    // Furnitur & Interior
    const CategoryIcon(
      name: 'weekend',
      icon: Icons.weekend_rounded,
      label: 'Furnitur',
      description: 'Icon untuk layanan furnitur',
      category: 'Interior',
    ),
    const CategoryIcon(
      name: 'chair',
      icon: Icons.chair_rounded,
      label: 'Kursi',
      description: 'Icon untuk layanan kursi',
      category: 'Interior',
    ),
    const CategoryIcon(
      name: 'bed',
      icon: Icons.bed_rounded,
      label: 'Tempat Tidur',
      description: 'Icon untuk layanan tempat tidur',
      category: 'Interior',
    ),
    
    // Makanan & Kuliner
    const CategoryIcon(
      name: 'restaurant',
      icon: Icons.restaurant_rounded,
      label: 'Restoran',
      description: 'Icon untuk layanan makanan',
      category: 'Kuliner',
    ),
    const CategoryIcon(
      name: 'restaurant_menu',
      icon: Icons.restaurant_menu_rounded,
      label: 'Menu Restoran',
      description: 'Icon untuk layanan catering',
      category: 'Kuliner',
    ),
    const CategoryIcon(
      name: 'cake',
      icon: Icons.cake_rounded,
      label: 'Kue',
      description: 'Icon untuk layanan kue',
      category: 'Kuliner',
    ),
    const CategoryIcon(
      name: 'local_cafe',
      icon: Icons.local_cafe_rounded,
      label: 'Kafe',
      description: 'Icon untuk layanan kafe',
      category: 'Kuliner',
    ),
    
    // Pakaian & Laundry
    const CategoryIcon(
      name: 'local_laundry_service',
      icon: Icons.local_laundry_service_rounded,
      label: 'Laundry',
      description: 'Icon untuk layanan laundry',
      category: 'Pakaian',
    ),
    const CategoryIcon(
      name: 'dry_cleaning',
      icon: Icons.dry_cleaning_rounded,
      label: 'Dry Cleaning',
      description: 'Icon untuk layanan dry cleaning',
      category: 'Pakaian',
    ),
    
    // Kecantikan & Kesehatan
    const CategoryIcon(
      name: 'spa',
      icon: Icons.spa_rounded,
      label: 'Spa',
      description: 'Icon untuk layanan spa',
      category: 'Kecantikan',
    ),
    const CategoryIcon(
      name: 'cut',
      icon: Icons.cut_rounded,
      label: 'Potong Rambut',
      description: 'Icon untuk layanan salon',
      category: 'Kecantikan',
    ),
    const CategoryIcon(
      name: 'healing',
      icon: Icons.healing_rounded,
      label: 'Kesehatan',
      description: 'Icon untuk layanan kesehatan',
      category: 'Kesehatan',
    ),
    const CategoryIcon(
      name: 'medical_services',
      icon: Icons.medical_services_rounded,
      label: 'Layanan Medis',
      description: 'Icon untuk layanan medis',
      category: 'Kesehatan',
    ),
    
    // Pendidikan & Pelatihan
    const CategoryIcon(
      name: 'menu_book',
      icon: Icons.menu_book_rounded,
      label: 'Buku',
      description: 'Icon untuk layanan pendidikan',
      category: 'Pendidikan',
    ),
    const CategoryIcon(
      name: 'school',
      icon: Icons.school_rounded,
      label: 'Sekolah',
      description: 'Icon untuk layanan sekolah',
      category: 'Pendidikan',
    ),
    const CategoryIcon(
      name: 'psychology',
      icon: Icons.psychology_rounded,
      label: 'Psikologi',
      description: 'Icon untuk layanan konseling',
      category: 'Pendidikan',
    ),
    
    // Desain & Kreatif
    const CategoryIcon(
      name: 'design_services',
      icon: Icons.design_services_rounded,
      label: 'Layanan Desain',
      description: 'Icon untuk layanan desain',
      category: 'Kreatif',
    ),
    const CategoryIcon(
      name: 'brush',
      icon: Icons.brush_rounded,
      label: 'Lukis',
      description: 'Icon untuk layanan seni',
      category: 'Kreatif',
    ),
    
    // Media & Fotografi
    const CategoryIcon(
      name: 'camera_alt',
      icon: Icons.camera_alt_rounded,
      label: 'Kamera',
      description: 'Icon untuk layanan fotografi',
      category: 'Media',
    ),
    const CategoryIcon(
      name: 'videocam',
      icon: Icons.videocam_rounded,
      label: 'Video',
      description: 'Icon untuk layanan video',
      category: 'Media',
    ),
    
    // Acara & Hiburan
    const CategoryIcon(
      name: 'celebration',
      icon: Icons.celebration_rounded,
      label: 'Perayaan',
      description: 'Icon untuk layanan acara',
      category: 'Acara',
    ),
    const CategoryIcon(
      name: 'event',
      icon: Icons.event_rounded,
      label: 'Acara',
      description: 'Icon untuk layanan event organizer',
      category: 'Acara',
    ),
    const CategoryIcon(
      name: 'music_note',
      icon: Icons.music_note_rounded,
      label: 'Musik',
      description: 'Icon untuk layanan musik',
      category: 'Hiburan',
    ),
    
    // Hukum & Profesional
    const CategoryIcon(
      name: 'gavel',
      icon: Icons.gavel_rounded,
      label: 'Hukum',
      description: 'Icon untuk layanan hukum',
      category: 'Profesional',
    ),
    const CategoryIcon(
      name: 'account_balance',
      icon: Icons.account_balance_rounded,
      label: 'Keuangan',
      description: 'Icon untuk layanan keuangan',
      category: 'Profesional',
    ),
    
    // Lainnya
    const CategoryIcon(
      name: 'category',
      icon: Icons.category_rounded,
      label: 'Kategori Lainnya',
      description: 'Icon untuk kategori lainnya',
      category: 'Lainnya',
    ),
    const CategoryIcon(
      name: 'miscellaneous_services',
      icon: Icons.miscellaneous_services_rounded,
      label: 'Layanan Lainnya',
      description: 'Icon untuk layanan lainnya',
      category: 'Lainnya',
    ),
  ];
  
  /// Mendapatkan daftar kategori icon
  static List<String> getIconCategories() {
    final categories = allIcons.map((icon) => icon.category).toSet().toList();
    categories.sort();
    return categories;
  }
  
  /// Mendapatkan daftar icon berdasarkan kategori
  static List<CategoryIcon> getIconsByCategory(String category) {
    return allIcons.where((icon) => icon.category == category).toList();
  }
  
  /// Mendapatkan CategoryIcon berdasarkan nama ikon
  static CategoryIcon? getCategoryIconByName(String iconName) {
    if (iconName.isEmpty) return null;
    
    try {
      return allIcons.firstWhere(
        (icon) => icon.name == iconName || 
                  icon.name == iconName.replaceAll('_rounded', '') ||
                  '${icon.name}_rounded' == iconName
      );
    } catch (e) {
      // Normalisasi nama
      String normalizedName = iconName;
      if (iconName.endsWith('_rounded')) {
        normalizedName = iconName.substring(0, iconName.length - 8);
      }
      
      try {
        return allIcons.firstWhere((icon) => 
          icon.name == normalizedName || 
          normalizedName.contains(icon.name) || 
          icon.name.contains(normalizedName)
        );
      } catch (e) {
        return null;
      }
    }
  }

  /// Mendapatkan ikon Material berdasarkan nama ikon
  static IconData? getIconByName(String iconName) {
    if (iconName.isEmpty) return null;
    
    // 1. Coba cari kecocokan langsung
    try {
      final icon = allIcons.firstWhere((icon) => 
        icon.name == iconName || 
        icon.name == iconName.replaceAll('_rounded', '') ||
        '${icon.name}_rounded' == iconName
      );
      logger.d('  ✅ Ditemukan icon langsung: "${icon.name}" -> ${icon.icon}');
      return icon.icon;
    } catch (e) {
      // Tidak ditemukan kecocokan langsung, lanjutkan ke pencarian berikutnya
      logger.d('  ⚠️ Tidak ditemukan kecocokan langsung untuk "$iconName"');
    }
    
    // 2. Coba hapus suffix _rounded jika ada
    String normalizedName = iconName;
    if (iconName.endsWith('_rounded')) {
      normalizedName = iconName.substring(0, iconName.length - 8); // hapus "_rounded"
      logger.d('  🔄 Menormalkan nama: "$iconName" -> "$normalizedName"');
    }
    
    // 3. Cari dengan nama yang sudah dinormalisasi
    try {
      final icon = allIcons.firstWhere((icon) => icon.name == normalizedName);
      logger.d('  ✅ Ditemukan kecocokan setelah normalisasi: "$normalizedName" -> ${icon.icon}');
      return icon.icon;
    } catch (e) {
      // Tidak ditemukan kecocokan setelah normalisasi, lanjutkan ke pencarian berikutnya
      logger.d('  ⚠️ Tidak ditemukan kecocokan setelah normalisasi untuk "$normalizedName"');
    }
    
    // 4. Coba cari kecocokan substring (untuk menangani kasus seperti "construction_rounded" vs "construction")
    try {
      final matchedIcon = allIcons.firstWhere(
        (icon) => normalizedName.contains(icon.name) || icon.name.contains(normalizedName),
        orElse: () => allIcons.firstWhere((icon) => icon.name == 'category', orElse: () => allIcons[0])
      );
      
      if (matchedIcon.name != 'category' && matchedIcon.name != allIcons[0].name) {
        logger.d('  ✅ Ditemukan kecocokan substring: "$normalizedName" -> ${matchedIcon.name} -> ${matchedIcon.icon}');
        return matchedIcon.icon;
      }
      
      // 5. Jika masih tidak ditemukan, coba gunakan map khusus untuk nama ikon yang umum
      final specialIconMap = <String, String>{
        'construction_rounded': 'construction',
        'directions_bus_rounded': 'directions_bus',
        'computer_rounded': 'computer',
        'yard_rounded': 'yard',
        'local_shipping_rounded': 'local_shipping',
        'build_circle_outlined': 'build',
        'school_rounded': 'school',
        'two_wheeler_rounded': 'two_wheeler',
        'directions_car_rounded': 'directions_car',
        'health_and_safety_rounded': 'health_and_safety',
        'cleaning_services_rounded': 'cleaning_services',
        'deck_rounded': 'deck',
        'cottage_rounded': 'cottage',
        'pets_rounded': 'pets',
        'celebration_rounded': 'celebration',
        'design_services_rounded': 'design_services',
        'request_quote_rounded': 'request_quote',
      };
      
      if (specialIconMap.containsKey(iconName)) {
        final mappedName = specialIconMap[iconName]!;
        logger.d('  🔄 Menggunakan pemetaan khusus: "$iconName" -> "$mappedName"');
        
        try {
          final result = allIcons.firstWhere((icon) => icon.name == mappedName);
          logger.d('  ✅ Ditemukan kecocokan dari pemetaan khusus: "$mappedName" -> ${result.icon}');
          return result.icon;
        } catch (e) {
          // Tidak ditemukan kecocokan dari pemetaan khusus
        }
      }
      
      // 6. Jika semua langkah gagal, gunakan ikon default
      logger.d('  ⚠️ Tidak ditemukan icon untuk nama: "$iconName", menggunakan default');
      return null;
    } catch (e) {
      logger.e('  ❌ Error saat mencari icon: $e');
      return null;
    }
  }
  
  /// Peta kategori ke ikon Material Icons
  static const Map<String, IconData> _categoryIconDataMap = {
    // Kategori Spesifik (prioritas tertinggi)
    'tukang bangunan': Icons.construction_rounded,
    'perbaikan & instalasi': Icons.build_circle_outlined,
    'pindahan & angkut': Icons.local_shipping_rounded,
    'otomotif (motor)': Icons.two_wheeler_rounded,
    'otomotif (mobil)': Icons.directions_car_rounded,
    'home interior': Icons.deck_rounded,
    'home exterior': Icons.cottage_rounded,
    'hewan peliharaan': Icons.pets_rounded,
    'desain & kreatif': Icons.design_services_rounded,
    'administrasi & keuangan': Icons.request_quote_rounded,

    // Kata Kunci Umum
    'bersih-bersih': Icons.cleaning_services_rounded,
    'kebersihan': Icons.cleaning_services_rounded,
    'pembersihan': Icons.cleaning_services_rounded,
    'cleaning': Icons.cleaning_services_rounded,
    
    'perbaikan': Icons.handyman_rounded,
    'reparasi': Icons.handyman_rounded,
    'servis': Icons.handyman_rounded,
    'repair': Icons.handyman_rounded,
    'tukang': Icons.construction_rounded, // fallback untuk tukang
    
    'elektronik': Icons.electrical_services_rounded,
    'electronics': Icons.electrical_services_rounded,
    
    'komputer': Icons.computer_rounded,
    'laptop': Icons.laptop_rounded,
    'computer': Icons.computer_rounded,
    
    'mobil': Icons.directions_car_rounded,
    'kendaraan': Icons.directions_car_rounded,
    'car': Icons.directions_car_rounded,
    
    'motor': Icons.two_wheeler_rounded,
    'motorcycle': Icons.two_wheeler_rounded,
    
    'rumah': Icons.house_rounded,
    'perumahan': Icons.house_rounded,
    'house': Icons.house_rounded,
    'home': Icons.house_rounded,
    
    'taman': Icons.yard_rounded,
    'kebun': Icons.yard_rounded,
    'garden': Icons.yard_rounded,
    
    'listrik': Icons.electrical_services_rounded,
    'electric': Icons.electrical_services_rounded,
    'electricity': Icons.electrical_services_rounded,
    
    'pipa': Icons.plumbing_rounded,
    'ledeng': Icons.plumbing_rounded,
    'plumbing': Icons.plumbing_rounded,
    
    'cat': Icons.format_paint_rounded,
    'painting': Icons.format_paint_rounded,
    
    'furniture': Icons.weekend_rounded,
    'mebel': Icons.weekend_rounded,
    
    'masak': Icons.restaurant_rounded,
    'memasak': Icons.restaurant_rounded,
    'cooking': Icons.restaurant_rounded,
    
    'catering': Icons.restaurant_menu_rounded,
    'makanan': Icons.restaurant_menu_rounded,
    'food': Icons.restaurant_menu_rounded,
    
    'laundry': Icons.local_laundry_service_rounded,
    'cuci': Icons.local_laundry_service_rounded,
    'pakaian': Icons.local_laundry_service_rounded,
    
    'kecantikan': Icons.healing_rounded,  // Ubah ke healing untuk konsistensi
    'beauty': Icons.healing_rounded,
    'salon': Icons.cut_rounded,
    'kecantikan & kesehatan': Icons.healing_rounded,
    'kecantikan dan kesehatan': Icons.healing_rounded,
    'beauty & health': Icons.healing_rounded,
    
    'kesehatan': Icons.healing_rounded,  // Ubah ke healing untuk konsistensi
    'health': Icons.healing_rounded,
    
    'pendidikan': Icons.menu_book_rounded,  // Ubah ke menu_book untuk konsistensi
    'education': Icons.menu_book_rounded,
    'les': Icons.menu_book_rounded,
    'kursus': Icons.menu_book_rounded,
    'pelatihan': Icons.menu_book_rounded,  // Ubah ke menu_book untuk konsistensi
    'training': Icons.menu_book_rounded,
    'pendidikan & pelatihan': Icons.menu_book_rounded,
    'pendidikan dan pelatihan': Icons.menu_book_rounded,
    'education & training': Icons.menu_book_rounded,
    
    'desain': Icons.design_services_rounded,
    'design': Icons.design_services_rounded,
    
    'fotografi': Icons.camera_alt_rounded,
    'photography': Icons.camera_alt_rounded,
    
    'video': Icons.videocam_rounded,
    'videografi': Icons.videocam_rounded,
    
    'acara': Icons.celebration_rounded,
    'event': Icons.celebration_rounded,
    
    'transportasi': Icons.directions_bus_rounded,
    'transport': Icons.directions_bus_rounded,
    
    'hukum': Icons.gavel_rounded,
    'legal': Icons.gavel_rounded,
    
    'teknologi': Icons.computer_rounded,
    'technology': Icons.computer_rounded,
    'it': Icons.computer_rounded,
    
    'lainnya': Icons.category_rounded,
    'other': Icons.category_rounded,
  };

  /// Daftar ikon Material Icons default yang unik untuk setiap kategori
  /// Setiap icon dalam daftar ini harus unik dan tidak boleh sama dengan icon yang sudah ada di _categoryIconDataMap
  static final Map<String, IconData> _uniqueDefaultIcons = {
    'umum': Icons.category_rounded,
    'jasa': Icons.handshake_rounded,
    'layanan': Icons.support_agent_rounded,
    'profesional': Icons.badge_rounded,
    'rumah_tangga': Icons.home_rounded,
    'outdoor': Icons.terrain_rounded,
    'peralatan': Icons.hardware_rounded,
    'konstruksi': Icons.architecture_rounded,
    'pertanian': Icons.agriculture_rounded,
    'peternakan': Icons.pets_rounded,
    'perikanan': Icons.water_rounded,
    'kerajinan': Icons.palette_rounded,
    'seni': Icons.brush_rounded,
    'musik': Icons.music_note_rounded,
    'hiburan': Icons.celebration_rounded,
    'olahraga': Icons.sports_rounded,
    'rekreasi': Icons.beach_access_rounded,
    'perjalanan': Icons.luggage_rounded,
    'keamanan': Icons.security_rounded,
    'komunikasi': Icons.connect_without_contact_rounded,
    'media': Icons.perm_media_rounded,
    'bisnis': Icons.business_center_rounded,
    'keuangan': Icons.account_balance_rounded,
    'konsultasi': Icons.support_rounded,
    'administrasi': Icons.assignment_rounded,
    'pemasaran': Icons.campaign_rounded,
    'penelitian': Icons.science_rounded,
    'pengembangan': Icons.trending_up_rounded,
    'pelatihan': Icons.school_rounded,
    'sosial': Icons.groups_rounded,
    'kesejahteraan': Icons.volunteer_activism_rounded,
    'lingkungan': Icons.eco_rounded,
    'agama': Icons.temple_buddhist_rounded,
    'budaya': Icons.theater_comedy_rounded,
    'tradisional': Icons.history_edu_rounded,
    'modern': Icons.rocket_launch_rounded,
    'digital': Icons.devices_rounded,
    'virtual': Icons.view_in_ar_rounded, // Mengganti vr_rounded yang tidak tersedia dengan view_in_ar_rounded
    'online': Icons.language_rounded,
    'offline': Icons.store_rounded
  };

  /// Peta kategori ke URL ikon default
  static const Map<String, String> _categoryIconMap = {
    'bersih-bersih': 'https://cdn-icons-png.flaticon.com/512/3343/3343641.png',
    'kebersihan': 'https://cdn-icons-png.flaticon.com/512/3343/3343641.png',
    'pembersihan': 'https://cdn-icons-png.flaticon.com/512/3343/3343641.png',
    'cleaning': 'https://cdn-icons-png.flaticon.com/512/3343/3343641.png',
    
    'perbaikan': 'https://cdn-icons-png.flaticon.com/512/1995/1995470.png',
    'reparasi': 'https://cdn-icons-png.flaticon.com/512/1995/1995470.png',
    'servis': 'https://cdn-icons-png.flaticon.com/512/1995/1995470.png',
    'repair': 'https://cdn-icons-png.flaticon.com/512/1995/1995470.png',
    
    'elektronik': 'https://cdn-icons-png.flaticon.com/512/3659/3659899.png',
    'electronics': 'https://cdn-icons-png.flaticon.com/512/3659/3659899.png',
    
    'komputer': 'https://cdn-icons-png.flaticon.com/512/3067/3067260.png',
    'laptop': 'https://cdn-icons-png.flaticon.com/512/3067/3067260.png',
    'computer': 'https://cdn-icons-png.flaticon.com/512/3067/3067260.png',
    
    'mobil': 'https://cdn-icons-png.flaticon.com/512/3097/3097180.png',
    'kendaraan': 'https://cdn-icons-png.flaticon.com/512/3097/3097180.png',
    'car': 'https://cdn-icons-png.flaticon.com/512/3097/3097180.png',
    
    'motor': 'https://cdn-icons-png.flaticon.com/512/5528/5528888.png',
    'motorcycle': 'https://cdn-icons-png.flaticon.com/512/5528/5528888.png',
    
    'rumah': 'https://cdn-icons-png.flaticon.com/512/2163/2163350.png',
    'perumahan': 'https://cdn-icons-png.flaticon.com/512/2163/2163350.png',
    'house': 'https://cdn-icons-png.flaticon.com/512/2163/2163350.png',
    'home': 'https://cdn-icons-png.flaticon.com/512/2163/2163350.png',
    
    'taman': 'https://cdn-icons-png.flaticon.com/512/2659/2659991.png',
    'kebun': 'https://cdn-icons-png.flaticon.com/512/2659/2659991.png',
    'garden': 'https://cdn-icons-png.flaticon.com/512/2659/2659991.png',
    
    'listrik': 'https://cdn-icons-png.flaticon.com/512/2761/2761541.png',
    'electric': 'https://cdn-icons-png.flaticon.com/512/2761/2761541.png',
    'electricity': 'https://cdn-icons-png.flaticon.com/512/2761/2761541.png',
    
    'pipa': 'https://cdn-icons-png.flaticon.com/512/1186/1186715.png',
    'ledeng': 'https://cdn-icons-png.flaticon.com/512/1186/1186715.png',
    'plumbing': 'https://cdn-icons-png.flaticon.com/512/1186/1186715.png',
    
    'cat': 'https://cdn-icons-png.flaticon.com/512/1752/1752307.png',
    'painting': 'https://cdn-icons-png.flaticon.com/512/1752/1752307.png',
    
    'furniture': 'https://cdn-icons-png.flaticon.com/512/2400/2400622.png',
    'mebel': 'https://cdn-icons-png.flaticon.com/512/2400/2400622.png',
    
    'masak': 'https://cdn-icons-png.flaticon.com/512/1830/1830839.png',
    'memasak': 'https://cdn-icons-png.flaticon.com/512/1830/1830839.png',
    'cooking': 'https://cdn-icons-png.flaticon.com/512/1830/1830839.png',
    
    'catering': 'https://cdn-icons-png.flaticon.com/512/6978/6978255.png',
    'makanan': 'https://cdn-icons-png.flaticon.com/512/6978/6978255.png',
    'food': 'https://cdn-icons-png.flaticon.com/512/6978/6978255.png',
    
    'laundry': 'https://cdn-icons-png.flaticon.com/512/2975/2975175.png',
    'cuci': 'https://cdn-icons-png.flaticon.com/512/2975/2975175.png',
    'pakaian': 'https://cdn-icons-png.flaticon.com/512/2975/2975175.png',
    
    'kecantikan': 'https://cdn-icons-png.flaticon.com/512/4129/4129443.png',
    'beauty': 'https://cdn-icons-png.flaticon.com/512/4129/4129443.png',
    'salon': 'https://cdn-icons-png.flaticon.com/512/3163/3163199.png',
    'kecantikan & kesehatan': 'https://cdn-icons-png.flaticon.com/512/2966/2966327.png',
    'kecantikan dan kesehatan': 'https://cdn-icons-png.flaticon.com/512/2966/2966327.png',
    'beauty & health': 'https://cdn-icons-png.flaticon.com/512/2966/2966327.png',
    
    'kesehatan': 'https://cdn-icons-png.flaticon.com/512/2966/2966327.png',
    'health': 'https://cdn-icons-png.flaticon.com/512/2966/2966327.png',
    
    'pendidikan': 'https://cdn-icons-png.flaticon.com/512/3079/3079022.png',
    'education': 'https://cdn-icons-png.flaticon.com/512/3079/3079022.png',
    'les': 'https://cdn-icons-png.flaticon.com/512/3079/3079022.png',
    'kursus': 'https://cdn-icons-png.flaticon.com/512/3079/3079022.png',
    'pendidikan & pelatihan': 'https://cdn-icons-png.flaticon.com/512/2232/2232688.png',
    'pendidikan dan pelatihan': 'https://cdn-icons-png.flaticon.com/512/2232/2232688.png',
    'education & training': 'https://cdn-icons-png.flaticon.com/512/2232/2232688.png',
    
    'desain': 'https://cdn-icons-png.flaticon.com/512/2920/2920277.png',
    'design': 'https://cdn-icons-png.flaticon.com/512/2920/2920277.png',
    
    'fotografi': 'https://cdn-icons-png.flaticon.com/512/1042/1042390.png',
    'photography': 'https://cdn-icons-png.flaticon.com/512/1042/1042390.png',
    
    'video': 'https://cdn-icons-png.flaticon.com/512/1179/1179120.png',
    'videografi': 'https://cdn-icons-png.flaticon.com/512/1179/1179120.png',
    
    'acara': 'https://cdn-icons-png.flaticon.com/512/3209/3209125.png',
    'event': 'https://cdn-icons-png.flaticon.com/512/3209/3209125.png',
    
    'transportasi': 'https://cdn-icons-png.flaticon.com/512/3097/3097140.png',
    'transport': 'https://cdn-icons-png.flaticon.com/512/3097/3097140.png',
    
    'hukum': 'https://cdn-icons-png.flaticon.com/512/2091/2091700.png',
    'legal': 'https://cdn-icons-png.flaticon.com/512/2091/2091700.png',
    
    'teknologi': 'https://cdn-icons-png.flaticon.com/512/3655/3655566.png',
    'technology': 'https://cdn-icons-png.flaticon.com/512/3655/3655566.png',
    'it': 'https://cdn-icons-png.flaticon.com/512/3655/3655566.png',
    
    'lainnya': 'https://cdn-icons-png.flaticon.com/512/2099/2099058.png',
    'other': 'https://cdn-icons-png.flaticon.com/512/2099/2099058.png',
  };
  
  /// Daftar ikon default jika tidak ada yang cocok
  static const List<String> _defaultIcons = [
    'https://cdn-icons-png.flaticon.com/512/2099/2099058.png',
    'https://cdn-icons-png.flaticon.com/512/1077/1077063.png',
    'https://cdn-icons-png.flaticon.com/512/3176/3176293.png',
    'https://cdn-icons-png.flaticon.com/512/4185/4185474.png',
    'https://cdn-icons-png.flaticon.com/512/2534/2534204.png',
  ];

  /// Mengekstrak kata kunci dari nama kategori
  static Set<String> _extractKeywords(String categoryName) {
    // Hapus karakter khusus dan ubah ke lowercase
    final cleanName = categoryName
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ') // Ganti karakter khusus dengan spasi
        .replaceAll(RegExp(r'\s+'), ' ') // Ganti multiple spasi dengan satu spasi
        .trim();
    
    // Pisahkan kata kunci
    final keywords = cleanName.split(' ').where((word) => word.length > 2).toSet();
    
    // Tambahkan variasi kata kunci
    final variations = <String>{};
    for (final word in keywords) {
      variations.add(word);
      
      // Tambahkan bentuk tunggal/jamak
      if (word.endsWith('an')) {
        variations.add(word.substring(0, word.length - 2)); // Hapus 'an' di akhir
      } else if (word.endsWith('i')) {
        variations.add('${word}an'); // Tambahkan 'an' di akhir
      }
    }
    
    return variations;
  }

  /// Mendapatkan URL ikon default secara deterministik berdasarkan nama kategori
  static String _getDefaultIconUrl(String categoryName) {
    if (categoryName.isEmpty) {
      return _defaultIcons[0];
    }
    
    // Gunakan hash dari nama kategori untuk memilih ikon secara deterministik
    final hash = categoryName.codeUnits.fold(0, (a, b) => a + b);
    final index = hash % _defaultIcons.length;
    return _defaultIcons[index];
  }

  /// Mendapatkan URL ikon yang sesuai untuk kategori tertentu
  static String getIconUrl(String categoryName) {
    if (categoryName.isEmpty) {
      return _getDefaultIconUrl(categoryName);
    }
    
    final lowerCaseName = categoryName.toLowerCase().trim();
    
    // Debug: Cetak nama kategori yang diproses
    logger.d('Mencari ikon untuk kategori: "$lowerCaseName"');
    
    // 1. Coba cari kecocokan langsung terlebih dahulu
    if (_categoryIconMap.containsKey(lowerCaseName)) {
      final iconUrl = _categoryIconMap[lowerCaseName]!;
      logger.d('  ✅ Ditemukan kecocokan langsung: "$lowerCaseName" -> "$iconUrl"');
      return iconUrl;
    }
    
    // 2. Cek untuk kategori khusus dengan nama panjang
    final specialMappings = {
      'kecantikan & kesehatan': 'kecantikan & kesehatan',
      'kesehatan & kecantikan': 'kecantikan & kesehatan',
      'pendidikan & pelatihan': 'pendidikan & pelatihan',
      'pelatihan & pendidikan': 'pendidikan & pelatihan',
      'kecantikan kesehatan': 'kecantikan & kesehatan',  // Tanpa & untuk jaga-jaga
      'pendidikan pelatihan': 'pendidikan & pelatihan',  // Tanpa & untuk jaga-jaga
    };
    
    for (final entry in specialMappings.entries) {
      if (lowerCaseName == entry.key) {
        final iconUrl = _categoryIconMap[entry.value]!;
        logger.d('  ✅ Ditemukan pemetaan khusus: "$lowerCaseName" -> "${entry.value}" -> "$iconUrl"');
        return iconUrl;
      }
    }
    
    // 3. Cek kata kunci individual
    final keywords = _extractKeywords(lowerCaseName);
    logger.d('  🔍 Mengekstrak kata kunci: $keywords');
    
    for (final keyword in keywords) {
      // Cari kata kunci yang cocok di peta ikon
      for (final entry in _categoryIconMap.entries) {
        if (keyword == entry.key) {
          logger.d('  ✅ Ditemukan kata kunci: "$keyword" -> "${entry.value}"');
          return entry.value;
        }
      }
    }
    
    // 4. Cek substring untuk kata kunci yang lebih panjang
    for (final entry in _categoryIconMap.entries) {
      if (lowerCaseName.contains(entry.key) && entry.key.length > 2) {  // Minimal 3 karakter untuk menghindari false positive
        logger.d('  🔍 Ditemukan substring: "${entry.key}" dalam "$lowerCaseName" -> "${entry.value}"');
        return entry.value;
      }
    }
    
    // Jika tidak ada yang cocok, gunakan ikon default secara deterministik
    final defaultIcon = _getDefaultIconUrl(categoryName);
    logger.d('  Menggunakan ikon default: $defaultIcon');
    return defaultIcon;
  }


  /// Mendapatkan ikon Material Icons default yang unik berdasarkan nama kategori
  static IconData _getDefaultIconData(String categoryName) {
    if (categoryName.isEmpty) {
      return _uniqueDefaultIcons['umum']!;
    }
    
    // Ekstrak kata kunci dari nama kategori
    final keywords = _extractKeywords(categoryName);
    
    // Coba temukan kecocokan kata kunci dengan kunci di _uniqueDefaultIcons
    for (final keyword in keywords) {
      for (final entry in _uniqueDefaultIcons.entries) {
        if (keyword.contains(entry.key) || entry.key.contains(keyword)) {
          logger.d('  🔍 Menemukan icon default unik untuk kata kunci: "$keyword" -> ${entry.key}');
          return entry.value;
        }
      }
    }
    
    // Jika tidak ada kecocokan kata kunci, gunakan pendekatan deterministik berdasarkan huruf pertama
    if (categoryName.isNotEmpty) {
      final firstChar = categoryName.toLowerCase()[0];
      final keys = _uniqueDefaultIcons.keys.toList();
      
      // Cari kunci yang dimulai dengan huruf yang sama
      for (final key in keys) {
        if (key.startsWith(firstChar)) {
          logger.d('  🔍 Menemukan icon default unik berdasarkan huruf pertama: "$firstChar" -> $key');
          return _uniqueDefaultIcons[key]!;
        }
      }
      
      // Jika tidak ada kecocokan huruf pertama, gunakan indeks berdasarkan posisi huruf dalam alfabet
      final charIndex = firstChar.codeUnitAt(0) - 'a'.codeUnitAt(0);
      final index = charIndex % keys.length;
      logger.d('  🔍 Menggunakan icon default unik berdasarkan indeks alfabet: "$firstChar" (indeks: $charIndex) -> ${keys[index]}');
      return _uniqueDefaultIcons[keys[index]]!;
    }
    
    // Fallback ke icon umum jika semua pendekatan gagal
    return _uniqueDefaultIcons['umum']!;
  }

  /// Mendapatkan IconData berdasarkan nama kategori dan nama ikon opsional
  static IconData getIconData(String categoryName, {String? iconName}) {
    // Debug: Cetak parameter yang diterima
    logger.d('🔍 CategoryIconMapper.getIconData:');
    logger.d('  • categoryName: "$categoryName"');
    logger.d('  • iconName: ${iconName ?? "<tidak ada>"}');
    
    // Tambahkan log untuk membantu troubleshooting
    logger.d('  📋 Keys di _categoryIconDataMap: ${_categoryIconDataMap.keys.join(", ")}');
    
    // 1. Jika iconName tersedia, coba gunakan itu terlebih dahulu
    if (iconName != null && iconName.isNotEmpty) {
      // Coba cari langsung di Icons class menggunakan reflection
      try {
        // Coba cari langsung di allIcons dengan kondisi yang lebih fleksibel
        final iconFromList = allIcons.firstWhere(
          (icon) => icon.name == iconName || 
                    '${icon.name}_rounded' == iconName ||
                    iconName.contains(icon.name) ||
                    icon.name.contains(iconName.replaceAll('_rounded', '')) ||
                    (iconName.replaceAll('_rounded', '').length > 3 && 
                     icon.name.contains(iconName.replaceAll('_rounded', ''))),
          orElse: () => throw Exception('Icon tidak ditemukan di allIcons')
        );
        logger.d('  ✅ Ditemukan di allIcons: "${iconFromList.name}" -> ${iconFromList.icon}');
        return iconFromList.icon;
      } catch (e) {
        logger.d('  ⚠️ Tidak ditemukan di allIcons: "$iconName", error: $e');
        
        // Coba dengan getIconByName yang memiliki logika pencarian lebih lengkap
        final iconData = getIconByName(iconName);
        if (iconData != null) {
          logger.d('  ✅ Ditemukan dengan getIconByName: "$iconName" -> $iconData');
          return iconData;
        }
        
        // Tambahan: Coba cari dengan normalisasi nama
        String normalizedName = iconName.replaceAll('_rounded', '');
        try {
          final matchedIcon = allIcons.firstWhere(
            (icon) => icon.name.contains(normalizedName) || normalizedName.contains(icon.name),
            orElse: () => throw Exception('Icon tidak ditemukan setelah normalisasi')
          );
          logger.d('  ✅ Ditemukan setelah normalisasi: "$normalizedName" -> ${matchedIcon.icon}');
          return matchedIcon.icon;
        } catch (e) {
          logger.d('  ⚠️ Icon tidak ditemukan untuk iconName: "$iconName" setelah normalisasi');
        }
      }
    }
    
    // 2. Jika iconName tidak tersedia atau tidak valid, coba gunakan nama kategori
    final lowerCaseName = categoryName.toLowerCase();
    logger.d('  🔍 Mencari di _categoryIconDataMap dengan key: "$lowerCaseName"');
    
    // Cek di peta ikon kategori
    if (_categoryIconDataMap.containsKey(lowerCaseName)) {
      final iconData = _categoryIconDataMap[lowerCaseName]!;
      logger.d('  ✅ Ditemukan di _categoryIconDataMap: "$lowerCaseName" -> $iconData');
      return iconData;
    } else {
      logger.d('  ⚠️ Tidak ditemukan di _categoryIconDataMap dengan key: "$lowerCaseName"');
    }
    
    // 3. Coba ekstrak kata kunci dari nama kategori
    final keywords = _extractKeywords(lowerCaseName);
    logger.d('  🔍 Kata kunci dari "$lowerCaseName": ${keywords.join(", ")}');
    
    for (final keyword in keywords) {
      if (_categoryIconDataMap.containsKey(keyword)) {
        final iconData = _categoryIconDataMap[keyword]!;
        logger.d('  ✅ Ditemukan untuk kata kunci: "$keyword" -> $iconData');
        return iconData;
      }
    }

    // 4. Cek substring sebagai fallback, tapi dengan prioritas panjang
    final sortedMapKeys = _categoryIconDataMap.keys.toList();
    sortedMapKeys.sort((a, b) => b.length.compareTo(a.length));
    logger.d('  🔍 Mencari dengan substring dari "$lowerCaseName"');

    for (final key in sortedMapKeys) {
      if (lowerCaseName.contains(key)) {
        logger.d('  ✅ Ditemukan substring: "$key" dalam "$lowerCaseName" -> ${_categoryIconDataMap[key]}');
        return _categoryIconDataMap[key]!;
      }
    }
    
    // 5. Coba cari di _uniqueDefaultIcons
    logger.d('  🔍 Mencari di _uniqueDefaultIcons untuk "$lowerCaseName"');
    logger.d('  📋 Keys di _uniqueDefaultIcons: ${_uniqueDefaultIcons.keys.join(", ")}');
    
    for (final entry in _uniqueDefaultIcons.entries) {
      if (lowerCaseName.contains(entry.key)) {
        logger.d('  ✅ Ditemukan di _uniqueDefaultIcons: "${entry.key}" dalam "$lowerCaseName" -> ${entry.value}');
        return entry.value;
      }
    }
    
    // 6. Jika tidak ada yang cocok, gunakan ikon default
    final defaultIcon = _getDefaultIconData(categoryName);
    logger.d('  ⚠️ Tidak ada ikon yang cocok untuk "$categoryName", menggunakan default: $defaultIcon');
    if (defaultIcon.codePoint == Icons.star.codePoint) {
      logger.w('  ⚠️ PERHATIAN: Menggunakan icon bintang default untuk kategori "$categoryName"');
    }
    return defaultIcon;
  }
  

}

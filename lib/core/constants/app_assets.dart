// Kelas ini berisi path ke file aset yang digunakan dalam aplikasi KlikJasa.
// Menggunakan konstanta untuk path aset membantu menghindari kesalahan ketik dan memudahkan pengelolaan.

class AppAssets {
  // Base path untuk gambar
  // Commented out since not currently used
  // static const String _imagesBasePath = 'assets/images';
  // Base path untuk logo
  static const String _logoBasePath = 'assets/logo';
  // Base path untuk ikon
  static const String _iconsBasePath = 'assets/icons';

  // Logo Aplikasi
  static const String appLogo = '$_logoBasePath/logo.png';
  static const String appLogoIcon = '$_iconsBasePath/logo.png';

  // Ilustrasi Umum

  // Ikon Kustom (jika tidak menggunakan Flutter Icons)
  // Ikon sosial media dan autentikasi
  static const String googleIcon = '$_iconsBasePath/google_icon.png';
  static const String appleIcon = '$_iconsBasePath/apple_icon.png';

  // Placeholder Images
  // Placeholder Images - dapat ditambahkan nanti sesuai kebutuhan
  // static const String placeholderService = '$_imagesBasePath/placeholders/service_placeholder.png';
  // static const String placeholderProfile = '$_imagesBasePath/placeholders/profile_placeholder.png';
}

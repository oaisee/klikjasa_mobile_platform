// Kelas ini berisi konstanta string yang digunakan di seluruh aplikasi KlikJasa.
// Menggunakan konstanta untuk string memudahkan pengelolaan teks dan lokalisasi.
// Semua string harus dalam Bahasa Indonesia sesuai permintaan.

class AppStrings {
  // Nama Aplikasi
  static const String appName = 'KlikJasa';

  // Umum
  static const String muatUlang = 'Muat Ulang';
  static const String cobaLagi = 'Coba Lagi';
  static const String simpan = 'Simpan';
  static const String simpanPerubahan = 'Simpan Perubahan';
  static const String batal = 'Batal';
  static const String tutup = 'Tutup';
  static const String ya = 'Ya';
  static const String tidak = 'Tidak';
  static const String selanjutnya = 'Selanjutnya';
  static const String kembali = 'Kembali';
  static const String selesai = 'Selesai';
  static const String lewati = 'Lewati';
  static const String kirim = 'Kirim';
  static const String cari = 'Cari...';
  static const String logout = 'Keluar';
  static const String statusPendingMessage = 'Pengajuan Anda sedang ditinjau. Mohon tunggu konfirmasi dari tim kami.';
  static const String statusVerifiedMessage = 'Selamat! Akun penyedia jasa Anda telah diverifikasi. Anda sekarang dapat mulai menawarkan layanan.';
  static const String statusRejectedMessage = 'Mohon maaf, pengajuan Anda belum dapat kami setujui saat ini. Silakan hubungi dukungan untuk informasi lebih lanjut.';
  static const String statusUnknownMessage = 'Status pengajuan Anda tidak diketahui. Silakan hubungi dukungan.';
  static const String providerApplicationStatus = 'Status Pengajuan Penyedia Jasa';
  static const String goToProviderDashboard = 'Masuk ke Dashboard Penyedia';
  static const String contactSupport = 'Hubungi Dukungan';
  static const String statusVerifiedShort = 'Penyedia Terverifikasi';
  static const String statusPendingShort = 'Menunggu Verifikasi';
  static const String statusRejectedShort = 'Pengajuan Ditolak';

  // Pesan Error Umum
  static const String errorTerjadiKesalahan = 'Terjadi kesalahan. Silakan coba lagi.';
  static const String errorKoneksiInternet = 'Tidak ada koneksi internet. Periksa jaringan Anda.';
  static const String errorServer = 'Server tidak merespons. Silakan coba beberapa saat lagi.';
  static const String errorInputTidakValid = 'Input tidak valid. Mohon periksa kembali.';
  static const String errorGagalMemperbaruiProfil = 'Gagal memperbarui profil. Silakan coba lagi.';

  // Splash Screen
  static const String splashScreenTitle = 'Selamat Datang di KlikJasa';
  static const String splashScreenSubtitle = 'Marketplace Jasa Terpercaya di Indonesia';

  // Autentikasi
  static const String login = 'Masuk';
  static const String daftar = 'Daftar';
  static const String email = 'Email';
  static const String password = 'Kata Sandi';
  static const String konfirmasiPassword = 'Konfirmasi Kata Sandi';
  static const String lupaPassword = 'Lupa Kata Sandi?';
  static const String belumPunyaAkun = 'Belum punya akun?';
  static const String sudahPunyaAkun = 'Sudah punya akun?';
  static const String selamatDatangKembali = 'Selamat Datang Kembali!';
  static const String masukUntukMelanjutkan = 'Masuk untuk melanjutkan ke KlikJasa.';
  static const String buatAkunBaru = 'Buat Akun Baru'; // Untuk judul di halaman registrasi
  static const String isiDataUntukDaftar = 'Isi data diri Anda untuk mendaftar.'; // Subjudul di halaman registrasi
  static const String namaLengkap = 'Nama Lengkap'; // Label untuk field nama lengkap
  static const String daftarUntukMemulai = 'Buat akun untuk memulai petualangan Anda.';
  static const String daftarDenganGoogle = 'Daftar dengan Google';
  static const String daftarDenganApple = 'Daftar dengan Apple';
  static const String atau = 'atau';
  static const String passwordsDoNotMatch = 'Kata sandi dan konfirmasi kata sandi tidak cocok.';

  // Halaman Beranda
  static const String beranda = 'Beranda';
  static const String kategori = 'Kategori';
  static const String pesanan = 'Pesanan';
  static const String profil = 'Profil';
  static const String saldoAnda = 'Saldo Anda:';
  static const String lihatSemua = 'Lihat Semua';
  static const String layananPopuler = 'Populer';
  static const String rekomendasiUntukAnda = 'Rekomendasi';
  static const String terbaru = 'Terbaru'; // Untuk Tab
  static const String kategoriLayanan = 'Kategori Layanan'; // Judul Seksi
  static const String rekomendasiPopuler = 'Rekomendasi & Populer'; // Judul Seksi
  static const String cariLayanan = 'Cari layanan...'; // Placeholder Search Bar

  // Halaman Profil
  static const String profilPengguna = 'Profil Pengguna'; // Judul halaman
  static const String namaPengguna = 'Nama Pengguna';
  static const String belumDiatur = 'Belum diatur';
  static const String tidakAdaEmail = 'Email tidak tersedia';
  static const String penggunaKlikJasa = 'Pengguna KlikJasa';
  static const String silakanLoginUntukMelihatProfil = 'Silakan masuk untuk melihat profil Anda.';
  static const String ubahProfil = 'Edit Profil';
  static const String daftarJadiPenyedia = 'Daftar Jadi Penyedia Jasa';
  static const String konfirmasiTopUp = 'Konfirmasi Top Up';
  static const String dasborPenyedia = 'Dasbor';
  static const String riwayatPesanan = 'Riwayat Pesanan';
  static const String metodePembayaran = 'Metode Pembayaran';
  static const String pengaturan = 'Pengaturan Akun';
  static const String bantuan = 'Bantuan & FAQ';
  // static const String daftarPenyediaJasa = 'Daftar Jadi Penyedia Jasa'; // Digantikan oleh registerAsProvider
  static const String dashboardPenyedia = 'Dashboard Penyedia';
  static const String segeraHadir = 'segera hadir!'; // Digunakan di _showComingSoon
  static const String isiSaldo = 'Isi Saldo';
  static const String saldoTidakCukup = 'Saldo Tidak Cukup';
  static const String keteranganSaldoTidakCukup = 'Saldo Anda Rp 0. Harap isi saldo terlebih dahulu untuk mendaftar sebagai penyedia jasa.';
  static const String ok = 'OK';
  static const String nomorTelepon = 'Nomor Telepon';
  static const String alamatLengkap = 'Alamat Lengkap';
  static const String kodePos = 'Kode Pos';
  static const String alamatPengiriman = 'Alamat Pengiriman'; // Untuk judul kartu alamat di profil
  static const String ubah = 'Edit Profil'; // Untuk tombol edit di kartu alamat
  static const String belumAdaAlamat = 'Alamat belum diatur.'; // Placeholder jika alamat kosong
  static const String alamat = 'Alamat'; // Untuk judul kartu alamat di profil (versi lebih umum)

  // Mode Tampilan Penyedia di Profil
  static const String providerModeActive = 'Mode Penyedia Aktif';
  static const String activateProviderMode = 'Aktifkan Mode Penyedia';
  static const String viewingAsProvider = 'Anda melihat sebagai penyedia jasa.';
  static const String switchToManageServices = 'Beralih untuk mengelola layanan Anda.';
  static const String registerAsProvider = 'Daftar sebagai Penyedia Jasa';

  // Notifikasi
  static const String notifikasi = 'Notifikasi';
  static const String belumAdaNotifikasi = 'Belum ada notifikasi baru.';
  static const String tandaiSemuaDibaca = 'Tandai semua dibaca';

  // Saldo
  static const String topUpSaldo = 'Top Up Saldo';
  static const String minimalTopUp = 'Minimal top up Rp 50.000';
  static const String saldoTidakCukupPesan = 'Saldo Anda tidak cukup untuk melakukan pemesanan.';
  static const String saldoTidakCukupAjukan = 'Saldo Anda tidak cukup untuk mengajukan sebagai penyedia jasa.';
  static const String topUp = 'Top Up'; // Untuk label tombol yang lebih pendek

  // Navigasi Bawah Mode Penyedia
  static const String navPenyediaDasbor = 'Dasbor';
  static const String navPenyediaLayanan = 'Layanan';
  static const String navPenyediaPesanan = 'Pesanan';
  // Untuk profil penyedia, bisa menggunakan AppStrings.profil jika labelnya sama
  
  // Tambahan string untuk navigasi penyedia
  static const String dasbor = 'Dasbor';
  static const String layanan = 'Layanan';

  // Tab Dasbor Penyedia
  static const String dasborRingkasan = 'Ringkasan';
  static const String dasborLayananSaya = 'Layanan Saya';
  static const String dasborPesananMasuk = 'Pesanan Masuk';

  // Navigasi Bawah Mode Pengguna Tambahan
  static const String navPencarian = 'Pencarian';

  // TODO: Tambahkan string lain sesuai kebutuhan fitur aplikasi

  // Dialog Konfirmasi Logout
  static const String konfirmasiLogout = 'Konfirmasi Keluar';
  static const String yakinInginKeluar = 'Apakah Anda yakin ingin keluar dari aplikasi?';

  // Admin Screen Strings
  static const String adminLoginTitle = 'Login Admin KlikJasa';
  static const String adminLoginSubtitle = 'Masukkan kredensial admin Anda.';
  static const String adminDashboardTitle = 'Dasbor Admin';
  
  // Admin Category Management
  static const String adminCategoryManagement = 'Manajemen Kategori Layanan';
  static const String addCategory = 'Tambah Kategori';
  static const String editCategory = 'Edit Kategori';
  static const String categoryName = 'Nama Kategori';
  static const String categoryDescription = 'Deskripsi Kategori';
  static const String categoryIconUrl = 'URL Ikon Kategori';
  static const String categoryStatus = 'Status Kategori';
  static const String categoryActive = 'Aktif';
  static const String categoryInactive = 'Tidak Aktif';
  static const String confirmDeleteCategory = 'Konfirmasi Hapus Kategori';
  static const String confirmDeleteCategoryMessage = 'Apakah Anda yakin ingin menghapus kategori ini? Tindakan ini tidak dapat dibatalkan.';
  static const String categoryDeleted = 'Kategori berhasil dihapus';
  static const String categorySaved = 'Kategori berhasil disimpan';
  
  // Syarat dan Ketentuan
  static const String termsAndConditions = 'Dengan mendaftar sebagai penyedia jasa, saya menyetujui syarat dan ketentuan yang berlaku di KlikJasa.';

  // Pengaturan
  static const String settings = 'Pengaturan';
  static const String settingsGeneral = 'Pengaturan Umum';
  static const String settingsAccount = 'Pengaturan Akun';
  static const String settingsNotification = 'Pengaturan Notifikasi';
  static const String settingsPrivacy = 'Pengaturan Privasi';
  static const String settingsSecurity = 'Pengaturan Keamanan';
}

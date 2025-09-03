# KlikJasa

KlikJasa adalah marketplace jasa modern dan minimalis yang dirancang untuk mempertemukan pengguna jasa dengan penyedia jasa terverifikasi di seluruh Indonesia. Aplikasi ini memfasilitasi transaksi, mengoptimalkan navigasi, dan memberikan pengalaman pengguna yang mulus dengan fokus pada kepercayaan dan transparansi melalui sistem manajemen saldo sebagai biaya aplikasi dan verifikasi ketat.

## Fitur Utama

- **Mode Pengguna Jasa**: Pencarian layanan, pemesanan, dan ulasan
- **Mode Penyedia Jasa**: Dashboard penyedia, manajemen pesanan, dan layanan
- **Sistem Chat**: Komunikasi real-time antara pengguna dan penyedia jasa
- **Sistem Notifikasi**: Pemberitahuan real-time untuk aktivitas penting
- **Manajemen Saldo**: Sistem pembayaran biaya aplikasi yang transparan
- **Verifikasi Penyedia**: Proses verifikasi untuk memastikan kualitas layanan

## Teknologi

- **Frontend**: Flutter
- **Backend**: Supabase (PostgreSQL, Auth, Storage, Functions)
- **State Management**: BLoC/Cubit
- **Dependency Injection**: get_it

## Struktur Proyek

Proyek ini menggunakan Clean Architecture dengan struktur folder yang diorganisir berdasarkan fitur (feature-based architecture). Lihat file `ANALISIS_DAN_AUDIT_APLIKASI.md` untuk detail lebih lanjut tentang struktur proyek.

## Logika biaya layanan dan saldo pengguna dan penyedia:
1. Saat checkout, saldo pengguna jasa dipotong sebesar persentase biaya platform ( service_fee_percentage ) dari total harga layanan.
2. Tidak ada transfer dana ke penyedia jasa melalui sistem. Saldo penyedia tidak terpengaruh pada tahap ini.
3. Jumlah yang dipotong dari pengguna jasa sepenuhnya menjadi pendapatan bagi platform/developer.

## Memulai

### Prasyarat

- Flutter SDK (versi terbaru)
- Dart SDK (versi terbaru)
- Supabase CLI (untuk pengembangan lokal)
- Editor kode (VS Code, Android Studio, dll.)

### Instalasi

1. Clone repositori ini
   ```bash
   git clone https://github.com/username/klik_jasa.git
   cd klik_jasa
   ```

2. Instal dependensi
   ```bash
   flutter pub get
   ```

3. Siapkan Supabase
   - Buat proyek Supabase baru
   - Jalankan migrasi database yang ada di folder `supabase/migrations`
   - Salin URL dan kunci API Supabase ke file `.env`

4. Jalankan aplikasi
   ```bash
   flutter run
   ```

5. Analisa aplikasi
   ```bash
   flutter analyze
   ```

## Dokumentasi

- **Dokumentasi API**: Lihat file `DOKUMENTASI_FUNGSI_RPC.md` untuk detail tentang fungsi-fungsi RPC Supabase yang digunakan dalam aplikasi.
- **Analisis dan Audit**: Lihat file `ANALISIS_DAN_AUDIT_APLIKASI.md` untuk analisis mendalam tentang aplikasi dan rekomendasi perbaikan.
- **Changelog**: Lihat file `CHANGELOG.md` untuk riwayat perubahan pada aplikasi.

## Kontribusi

Kontribusi selalu diterima! Silakan buat pull request atau buka issue untuk diskusi.

## Lisensi

Proyek ini dilisensikan di bawah lisensi MIT - lihat file LICENSE untuk detail.
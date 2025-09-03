import 'package:equatable/equatable.dart';

class ProviderSummaryDataEntity extends Equatable {
  final String providerId; // Menambahkan providerId untuk mendukung refresh
  final int pesananPerluTindakan;
  final double pendapatanBulanIni; // Menggunakan double untuk nilai moneter
  final double ratingRataRata;
  final int pesananAktif;
  final int pesananSelesai30Hari;
  final int ulasanBaru;
  final int layananAktif;
  // Tambahkan field lain jika diperlukan, misal status verifikasi, saldo, dll.
  
  // Getter untuk kompatibilitas dengan nama field dalam bahasa Inggris
  int get activeOrdersCount => pesananAktif;
  double get totalRevenue => pendapatanBulanIni;
  double get averageRating => ratingRataRata;
  int get totalRatings => ulasanBaru;
  int get completedOrdersCount => pesananSelesai30Hari;

  const ProviderSummaryDataEntity({
    this.providerId = '', // Default empty string
    required this.pesananPerluTindakan,
    required this.pendapatanBulanIni,
    required this.ratingRataRata,
    required this.pesananAktif,
    required this.pesananSelesai30Hari,
    required this.ulasanBaru,
    required this.layananAktif,
  });

  // Contoh nilai default atau 'empty' state jika diperlukan
  factory ProviderSummaryDataEntity.empty({String providerId = ''}) {
    return ProviderSummaryDataEntity(
      providerId: providerId,
      pesananPerluTindakan: 0,
      pendapatanBulanIni: 0.0,
      ratingRataRata: 0.0,
      pesananAktif: 0,
      pesananSelesai30Hari: 0,
      ulasanBaru: 0,
      layananAktif: 0,
    );
  }

  @override
  List<Object?> get props => [
        providerId,
        pesananPerluTindakan,
        pendapatanBulanIni,
        ratingRataRata,
        pesananAktif,
        pesananSelesai30Hari,
        ulasanBaru,
        layananAktif,
      ];
}
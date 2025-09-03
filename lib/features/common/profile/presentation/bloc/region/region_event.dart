part of 'region_bloc.dart';

abstract class RegionEvent extends Equatable {
  const RegionEvent();

  @override
  List<Object> get props => [];
}

// Event untuk mengambil daftar provinsi
class FetchProvinces extends RegionEvent {}

class FetchKabupatenKota extends RegionEvent {
  final String provinceId;
  const FetchKabupatenKota(this.provinceId);

  @override
  List<Object> get props => [provinceId];
}

class FetchKecamatan extends RegionEvent {
  final String kabupatenKotaId;
  const FetchKecamatan(this.kabupatenKotaId);

  @override
  List<Object> get props => [kabupatenKotaId];
}

class FetchDesaKelurahan extends RegionEvent {
  final String kecamatanId;
  const FetchDesaKelurahan(this.kecamatanId);

  @override
  List<Object> get props => [kecamatanId];
}

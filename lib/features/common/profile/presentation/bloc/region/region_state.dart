part of 'region_bloc.dart';

abstract class RegionState extends Equatable {
  const RegionState();

  @override
  List<Object?> get props => [];
}

class RegionInitial extends RegionState {}

class RegionLoading extends RegionState {}

class ProvincesLoaded extends RegionState {
  final List<Provinsi> provinces;

  const ProvincesLoaded(this.provinces);

  @override
  List<Object?> get props => [provinces];
}

class KabupatenKotaLoading extends RegionState {}

class KabupatenKotaLoaded extends RegionState {
  final List<KabupatenKota> kabupatenKotaList;

  const KabupatenKotaLoaded(this.kabupatenKotaList);

  @override
  List<Object?> get props => [kabupatenKotaList];
}

class KecamatanLoading extends RegionState {}

class KecamatanLoaded extends RegionState {
  final List<Kecamatan> kecamatanList;

  const KecamatanLoaded(this.kecamatanList);

  @override
  List<Object?> get props => [kecamatanList];
}

class DesaKelurahanLoading extends RegionState {}

class DesaKelurahanLoaded extends RegionState {
  final List<DesaKelurahan> desaKelurahanList;

  const DesaKelurahanLoaded(this.desaKelurahanList);

  @override
  List<Object?> get props => [desaKelurahanList];
}

// class RegenciesLoaded extends RegionState {
//   final List<KabupatenKota> regencies; // Anda perlu membuat model KabupatenKota
//   const RegenciesLoaded(this.regencies);
//   @override
//   List<Object?> get props => [regencies];
// }

class RegionError extends RegionState {
  final String message;

  const RegionError(this.message);

  @override
  List<Object?> get props => [message];
}

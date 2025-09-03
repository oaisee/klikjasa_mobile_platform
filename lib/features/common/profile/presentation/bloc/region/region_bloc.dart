import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../domain/entities/provinsi.dart';
import '../../../domain/entities/kabupaten_kota.dart';
import '../../../domain/entities/kecamatan.dart';
import '../../../domain/entities/desa_kelurahan.dart';
import '../../../domain/usecases/get_provinces_usecase.dart';
import '../../../domain/usecases/get_kabupaten_kota_usecase.dart';
import '../../../domain/usecases/get_kecamatan_usecase.dart';
import '../../../domain/usecases/get_desa_kelurahan_usecase.dart';
import 'package:klik_jasa/core/error/failures.dart'; // Perbaikan path import

part 'region_event.dart';
part 'region_state.dart';

class RegionBloc extends Bloc<RegionEvent, RegionState> {
  final GetProvincesUseCase getProvincesUseCase;
  final GetKabupatenKotaUseCase getKabupatenKotaUseCase;
  final GetKecamatanUseCase getKecamatanUseCase;
  final GetDesaKelurahanUseCase getDesaKelurahanUseCase;

  RegionBloc({
    required this.getProvincesUseCase,
    required this.getKabupatenKotaUseCase,
    required this.getKecamatanUseCase,
    required this.getDesaKelurahanUseCase,
  }) : super(RegionInitial()) {
    on<FetchProvinces>(_onFetchProvinces);
    on<FetchKabupatenKota>(_onFetchKabupatenKota);
    on<FetchKecamatan>(_onFetchKecamatan);
    on<FetchDesaKelurahan>(_onFetchDesaKelurahan);
  }

  Future<void> _onFetchProvinces(
    FetchProvinces event,
    Emitter<RegionState> emit,
  ) async {
    emit(RegionLoading());
    final failureOrProvinces =
        await getProvincesUseCase(); // Memanggil use case
    failureOrProvinces.fold(
      (failure) => emit(RegionError(_mapFailureToMessage(failure))),
      (provinces) => emit(ProvincesLoaded(provinces)),
    );
  }

  Future<void> _onFetchKabupatenKota(
    FetchKabupatenKota event,
    Emitter<RegionState> emit,
  ) async {
    emit(KabupatenKotaLoading());
    final failureOrKabupatenKotaList = await getKabupatenKotaUseCase(event.provinceId);
    failureOrKabupatenKotaList.fold(
      (failure) => emit(RegionError(_mapFailureToMessage(failure))),
      (kabupatenKotaList) => emit(KabupatenKotaLoaded(kabupatenKotaList)),
    );
  }

  Future<void> _onFetchKecamatan(
    FetchKecamatan event,
    Emitter<RegionState> emit,
  ) async {
    emit(KecamatanLoading());
    final failureOrKecamatanList = await getKecamatanUseCase(event.kabupatenKotaId);
    failureOrKecamatanList.fold(
      (failure) => emit(RegionError(_mapFailureToMessage(failure))),
      (kecamatanList) => emit(KecamatanLoaded(kecamatanList)),
    );
  }

  Future<void> _onFetchDesaKelurahan(
    FetchDesaKelurahan event,
    Emitter<RegionState> emit,
  ) async {
    emit(DesaKelurahanLoading());
    final failureOrDesaKelurahanList = await getDesaKelurahanUseCase(event.kecamatanId);
    failureOrDesaKelurahanList.fold(
      (failure) => emit(RegionError(_mapFailureToMessage(failure))),
      (desaKelurahanList) => emit(DesaKelurahanLoaded(desaKelurahanList)),
    );
  }

  String _mapFailureToMessage(Failure failure) {
    // Anda bisa membuat pesan yang lebih spesifik berdasarkan tipe failure
    // Misalnya, jika failure is NetworkFailure, return "Tidak ada koneksi internet."
    return failure.message;
  }
}

import 'package:dartz/dartz.dart';
import 'package:klik_jasa/core/error/failures.dart';
import 'package:klik_jasa/core/error/exceptions.dart';
import 'package:klik_jasa/features/provider_mode/dashboard/domain/entities/provider_summary_data_entity.dart';
import 'package:klik_jasa/features/provider_mode/dashboard/domain/repositories/provider_summary_repository.dart';
import 'package:klik_jasa/features/provider_mode/dashboard/data/datasources/provider_summary_remote_data_source.dart';
import 'dart:async';
import 'package:dio/dio.dart';

class ProviderSummaryRepositoryImpl implements ProviderSummaryRepository {
  final ProviderSummaryRemoteDataSource _remoteDataSource;

  ProviderSummaryRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<Failure, ProviderSummaryDataEntity>> getProviderSummaryData(String providerId) async {
    if (providerId.isEmpty) {
      return Left(ServerFailure(message: 'Provider ID tidak boleh kosong'));
    }
    try {
      final summaryModel = await _remoteDataSource.getProviderSummaryData(providerId);
      // Di sini, jika ProviderSummaryModel berbeda dari ProviderSummaryDataEntity,
      // lakukan konversi dari model ke entity.
      // Untuk saat ini, kita asumsikan remoteDataSource mengembalikan entity secara langsung
      // atau model yang identik dengan entity sehingga tidak perlu konversi eksplisit.
      // Jika ada model, contoh: final summaryEntity = summaryModel.toEntity();
      return Right(summaryModel); // summaryModel diasumsikan sebagai ProviderSummaryDataEntity
    } on DioException catch (e) {
      // Tangani error spesifik dari network request jika menggunakan Dio
      return Left(NetworkFailure(message: 'Gagal mengambil data dari server: ${e.message ?? "Terjadi kesalahan server"}'));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      // Tangani error umum lainnya
      return Left(ServerFailure(message: 'Terjadi kesalahan: ${e.toString()}'));
    }
  }

  @override
  Stream<Either<Failure, ProviderSummaryDataEntity>> watchProviderSummaryData(String providerId) {
    if (providerId.isEmpty) {
      return Stream.value(Left(ServerFailure(message: 'Provider ID tidak boleh kosong')));
    }
    try {
      return _remoteDataSource.watchProviderSummaryData(providerId).transform(
        StreamTransformer.fromHandlers(
          handleData: (summaryData, sink) {
            sink.add(Right(summaryData));
          },
          handleError: (error, stackTrace, sink) {
            if (error is ServerException) {
              sink.add(Left(ServerFailure(message: error.message)));
            } else {
              sink.add(Left(ServerFailure(message: 'Terjadi kesalahan: ${error.toString()}')));
            }
          },
        ),
      );
    } on ServerException catch (e) {
      return Stream.value(Left(ServerFailure(message: e.message)));
    } catch (e) {
      return Stream.value(Left(ServerFailure(message: 'Terjadi kesalahan: ${e.toString()}')));
    }
  }
}
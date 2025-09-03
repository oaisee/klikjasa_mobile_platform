import 'package:dartz/dartz.dart';
import 'package:klik_jasa/core/error/failures.dart';
import 'package:klik_jasa/features/provider_mode/dashboard/domain/entities/provider_summary_data_entity.dart';

abstract class ProviderSummaryRepository {
  Future<Either<Failure, ProviderSummaryDataEntity>> getProviderSummaryData(String providerId);
  Stream<Either<Failure, ProviderSummaryDataEntity>> watchProviderSummaryData(String providerId);
}